import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'services/quran_service.dart';
import 'services/audio_service.dart';
import 'models/quran_models.dart';
import 'settings_provider.dart';

final quranServiceProvider = Provider((ref) => QuranService());
final audioServiceProvider = Provider((ref) => QuranAudioService());
final audioErrorProvider = StateProvider<String?>((ref) => null);

enum PlaylistMode { surah, hizb, search }

final currentPlayingAyahProvider = StateNotifierProvider<AudioNotifier, Ayah?>((ref) {
  return AudioNotifier(ref);
});

final optimisticIsPlayingProvider = StateProvider<bool>((ref) => false);

final isPlayingProvider = StreamProvider<bool>((ref) {
  final player = ref.watch(audioServiceProvider);
  return player.playerStateStream.map((state) => state.playing);
});

class AudioNotifier extends StateNotifier<Ayah?> {
  final Ref ref;
  StreamSubscription<int?>? _indexSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  List<Ayah> _playlistAyahs = [];
  PlaylistMode _currentMode = PlaylistMode.surah;

  bool _isManuallySeeking = false;

  AudioNotifier(this.ref) : super(null) {
    _setupListener();
  }

  void _setupListener() {
    final audioService = ref.read(audioServiceProvider);
    
    _indexSubscription?.cancel();
    _indexSubscription = audioService.currentIndexStream.listen((index) {
      if (_isManuallySeeking) return;
      
      if (index != null && index >= 0 && index < _playlistAyahs.length) {
        final newAyah = _playlistAyahs[index];
        if (state?.number != newAyah.number) {
          state = newAyah;
          _announceAyah(newAyah);
        }
      }
    });

    _stateSubscription?.cancel();
    _stateSubscription = audioService.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        playNext(isAutoAdvance: true);
      }
    });
  }

  void _announceAyah(Ayah ayah) {
    HapticFeedback.lightImpact();
    SemanticsService.sendAnnouncement(
      ui.PlatformDispatcher.instance.views.first,
      'Verset ${ayah.numberInSurah} de la sourate ${ayah.surahName}', 
      ui.TextDirection.ltr,
    );
  }

  bool _isLoading = false;

  Future<void> playSurah(int surahNumber) async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      ref.read(audioErrorProvider.notifier).state = null;
      ref.read(optimisticIsPlayingProvider.notifier).state = true;
      _currentMode = PlaylistMode.surah;

      // First, show the surah name placeholder
      final surahs = await ref.read(surahsProvider.future);
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      final playingAyah = Ayah(
        number: -1,
        text: '',
        numberInSurah: 1,
        juz: 1,
        manzil: 1,
        page: 1,
        ruku: 1,
        hizbQuarter: 1,
        sajda: null,
        surahNumber: surahNumber,
        surahName: surah.name,
      );
      state = playingAyah;
      
      // Fetch ONLY the first ayah for instant playback start
      final service = ref.read(quranServiceProvider);
      final riwaya = ref.read(settingsProvider).riwaya;
      final fetchedAyahs = await service.getSurahAyahs(surahNumber, riwaya);

      if (fetchedAyahs.isNotEmpty) {
        _playlistAyahs = fetchedAyahs;
        _isManuallySeeking = true;
        
        _preCacheSurah(_playlistAyahs);
        
        final audioService = ref.read(audioServiceProvider);
        await audioService.setPlaylist(_playlistAyahs, initialIndex: 0);
        audioService.play();
        
        await Future.delayed(const Duration(milliseconds: 100));
        _isManuallySeeking = false;
      }
    } catch (e) {
      _isManuallySeeking = false;
      state = null;
      ref.read(optimisticIsPlayingProvider.notifier).state = false;
      debugPrint('playSurah error: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> playAyah(Ayah ayah) async {
    if (_isLoading) return; // Prevent rapid-fire clicks
    _isLoading = true;
    
    try {
      ref.read(audioErrorProvider.notifier).state = null;
      ref.read(optimisticIsPlayingProvider.notifier).state = true;
      _currentMode = PlaylistMode.surah;
      final audioService = ref.read(audioServiceProvider);
      
      // If already playing exactly this ayah, just toggle (play/pause)
      if (state?.number == ayah.number) {
        togglePlayPause();
        _isLoading = false;
        return;
      }

      _isManuallySeeking = true;
      
      // Update state immediately for UI feedback
      state = ayah;

      // Check if we need to load a new playlist
      bool sameSurah = _playlistAyahs.isNotEmpty && 
                     _playlistAyahs.first.surahNumber == ayah.surahNumber;
      
      if (!sameSurah) {
        final service = ref.read(quranServiceProvider);
        final riwaya = ref.read(settingsProvider).riwaya;
        final fetchedAyahs = await service.getSurahAyahs(ayah.surahNumber, riwaya);
        if (fetchedAyahs.isNotEmpty) {
           _playlistAyahs = fetchedAyahs;
        }
      }

      int index = _playlistAyahs.indexWhere((a) => a.number == ayah.number);
      if (index == -1) {
        _playlistAyahs = [ayah];
        index = 0;
        sameSurah = false;
      }

      _preCacheSurah(_playlistAyahs);

      if (!sameSurah) {
        await audioService.setPlaylist(_playlistAyahs, initialIndex: index);
      } else {
        // Pause first to stop the current stream immediately
        await audioService.pause();
        // Seek to the new position
        await audioService.seekToIndex(index);
        // Small delay to ensure the player state is synchronized
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Explicitly check for processing state if needed, but play() should be fine now
      // Don't wait for play() to finish to return control to the UI
      audioService.play();
      
      // Reduced delay to 100ms - just enough to let the stream stabilize
      await Future.delayed(const Duration(milliseconds: 100));
      _isManuallySeeking = false;
    } catch (e) {
      _isManuallySeeking = false;
      state = null;
      ref.read(audioErrorProvider.notifier).state = 
        'عذراً، تعذر تشغيل الصوت. يرجى التحقق من اتصالك بالإنترنت.';
      debugPrint('Audio error: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> playHizb(int hizbNumber) async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      ref.read(audioErrorProvider.notifier).state = null;
      ref.read(optimisticIsPlayingProvider.notifier).state = true;
      _currentMode = PlaylistMode.hizb;

      final service = ref.read(quranServiceProvider);
      final riwaya = ref.read(settingsProvider).riwaya;
      final fetchedAyahs = await service.getHizbQuarterAyahs((hizbNumber - 1) * 4 + 1, riwaya);

      if (fetchedAyahs.isNotEmpty) {
        _playlistAyahs = fetchedAyahs;
        state = _playlistAyahs.first;
        
        _isManuallySeeking = true;
        _preCacheSurah(_playlistAyahs);
        
        final audioService = ref.read(audioServiceProvider);
        await audioService.setPlaylist(_playlistAyahs, initialIndex: 0);
        audioService.play();
        
        await Future.delayed(const Duration(milliseconds: 100));
        _isManuallySeeking = false;
      }
    } catch (e) {
      _isManuallySeeking = false;
      state = null;
      ref.read(optimisticIsPlayingProvider.notifier).state = false;
      debugPrint('playHizb error: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> playThumun(int thumunIndex) async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      ref.read(audioErrorProvider.notifier).state = null;
      ref.read(optimisticIsPlayingProvider.notifier).state = true;
      _currentMode = PlaylistMode.hizb;

      final ayahs = await ref.read(thumunAyahsProvider(thumunIndex).future);

      if (ayahs.isNotEmpty) {
        _playlistAyahs = ayahs;
        state = _playlistAyahs.first;
        
        _isManuallySeeking = true;
        _preCacheSurah(_playlistAyahs);
        
        final audioService = ref.read(audioServiceProvider);
        await audioService.setPlaylist(_playlistAyahs, initialIndex: 0);
        audioService.play();
        
        await Future.delayed(const Duration(milliseconds: 100));
        _isManuallySeeking = false;
      }
    } catch (e) {
      _isManuallySeeking = false;
      state = null;
      ref.read(optimisticIsPlayingProvider.notifier).state = false;
      debugPrint('playThumun error: $e');
    } finally {
      _isLoading = false;
    }
  }

  void _preCacheSurah(List<Ayah> ayahs) {
    if (ayahs.isEmpty) return;
    // Fire and forget caching to prepare for potential Airplane mode
    ref.read(audioServiceProvider).preCacheSurah(ayahs);
  }

  Future<void> playNext({bool isAutoAdvance = false}) async {
    if (state == null) return;

    final audioService = ref.read(audioServiceProvider);
    
    // 1. Try to skip within current playlist (verses)
    if (audioService.hasNext) {
      await audioService.seekToNext();
      if (!audioService.playing) {
        audioService.play();
      }
      return;
    }

    // 2. If end of playlist, transition to next "container"
    if (_currentMode == PlaylistMode.surah) {
      if (state!.surahNumber < 114) {
        await playSurah(state!.surahNumber + 1);
      } else if (isAutoAdvance) {
        // End of Quran reached
        await stop();
      }
    } else if (_currentMode == PlaylistMode.hizb) {
      // Logic for Thumun or Hizb
      // We can use the current global thumun index to find the next one
      final currentThumun = ref.read(currentThumunIndexProvider);
      if (currentThumun < 480) {
        final nextThumun = currentThumun + 1;
        ref.read(currentThumunIndexProvider.notifier).state = nextThumun;
        await playThumun(nextThumun);
      } else if (isAutoAdvance) {
        await stop();
      }
    }
  }

  Future<void> playPrevious() async {
    if (state == null) return;

    final audioService = ref.read(audioServiceProvider);

    // 1. If playing > 3 seconds, restart current verse
    if (audioService.position.inSeconds > 3) {
      await audioService.seek(Duration.zero);
      return;
    }

    // 2. Try to skip back within current playlist
    if (audioService.hasPrevious) {
      await audioService.seekToPrevious();
      if (!audioService.playing) {
        audioService.play();
      }
      return;
    }

    // 3. If at start of playlist, transition to previous "container"
    if (_currentMode == PlaylistMode.surah) {
      if (state!.surahNumber > 1) {
        await playSurah(state!.surahNumber - 1);
        // Optional: seek to the last verse of the previous surah
        // This would require waiting for the playlist to load
      }
    } else if (_currentMode == PlaylistMode.hizb) {
      final currentThumun = ref.read(currentThumunIndexProvider);
      if (currentThumun > 1) {
        final prevThumun = currentThumun - 1;
        ref.read(currentThumunIndexProvider.notifier).state = prevThumun;
        await playThumun(prevThumun);
      }
    }
  }

  Future<void> stop() async {
    final player = ref.read(audioServiceProvider);
    
    // Reset state immediately for instant UI removal
    ref.read(optimisticIsPlayingProvider.notifier).state = false;
    state = null;
    _playlistAyahs = []; // Clear internal playlist
    
    await player.stop();
  }

  void togglePlayPause() {
    final player = ref.read(audioServiceProvider);
    if (state == null) return;

    final currentOptimistic = ref.read(optimisticIsPlayingProvider);
    final newOptimistic = !currentOptimistic;
    
    // Set manual toggle flag to ignore stream updates for a short duration
    ref.read(isManualToggleActiveProvider.notifier).state = true;
    ref.read(optimisticIsPlayingProvider.notifier).state = newOptimistic;

    // Fire and forget player operations for instant UI responsiveness
    if (player.playing) {
      player.pause();
    } else {
      player.resume();
    }
    
    // Reset the manual toggle flag after a short delay (enough for the stream to catch up)
    Future.delayed(const Duration(milliseconds: 800), () {
      ref.read(isManualToggleActiveProvider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    _indexSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}

final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final service = ref.watch(quranServiceProvider);
  return service.getSurahs();
});

final surahAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, surahNumber) async {
  final service = ref.watch(quranServiceProvider);
  final settings = ref.watch(settingsProvider);
  final riwaya = settings.riwaya;
  final includePhonetics = settings.showPhonetics;
  return service.getSurahAyahs(surahNumber, riwaya, includePhonetics: includePhonetics);
});

final hizbQuarterAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, quarterNumber) async {
  final service = ref.watch(quranServiceProvider);
  final settings = ref.watch(settingsProvider);
  final riwaya = settings.riwaya;
  final includePhonetics = settings.showPhonetics;
  return service.getHizbQuarterAyahs(quarterNumber, riwaya, includePhonetics: includePhonetics);
});

final thumunAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, thumunIndex) async {
  final quarterIndex = ((thumunIndex - 1) / 2).floor() + 1;
  final isFirstThumun = (thumunIndex - 1) % 2 == 0;
  
  final ayahs = await ref.watch(hizbQuarterAyahsProvider(quarterIndex).future);
  
  // Pre-fetch next quarter if we are nearing the end of current one for fluid navigation
  if (thumunIndex < 480) {
    final nextThumun = thumunIndex + 1;
    final nextQuarter = ((nextThumun - 1) / 2).floor() + 1;
    if (nextQuarter != quarterIndex) {
      // Fire and forget pre-fetch
      ref.read(hizbQuarterAyahsProvider(nextQuarter).future).catchError((_) => <Ayah>[]);
    }
  }

  final midPoint = (ayahs.length / 2).floor();
  return isFirstThumun ? ayahs.sublist(0, midPoint) : ayahs.sublist(midPoint);
});

final hizbFirstAyahProvider = FutureProvider.family<Ayah, int>((ref, hizbNumber) async {
  final startQuarter = (hizbNumber - 1) * 4 + 1;
  final ayahs = await ref.watch(hizbQuarterAyahsProvider(startQuarter).future);
  return ayahs.first;
});

// Providers for home page stats
final lastReadProvider = StateProvider<String>((ref) => 'سورة البقرة • آية 15');

final favoritesCountProvider = StateProvider<int>((ref) => 5);

final featuredAyahProvider = FutureProvider<Ayah>((ref) async {
  final service = ref.watch(quranServiceProvider);
  final now = DateTime.now();
  final isFriday = now.weekday == DateTime.friday;
  
  // Create a stable daily seed to keep the same verse all day
  final seed = now.year * 1000 + now.month * 100 + now.day;
  final random = Random(seed);

  try {
    if (isFriday) {
      // Pick from Surah Al-Kahf (18) on Fridays
      final surah18 = await service.getSurahAyahs(18, Riwaya.hafs);
      if (surah18.isNotEmpty) {
        return surah18[random.nextInt(surah18.length)];
      }
    }

    // Otherwise, pick a random ayah from the entire Quran (Global 1 to 6236)
    // We aim for a "premium" length (100-500 chars) to match the UI card space.
    for (int i = 0; i < 5; i++) {
      final globalNumber = random.nextInt(6236) + 1;
      final ayah = await service.getAyahByGlobalNumber(globalNumber);
      if (ayah != null && ayah.text.length >= 100 && ayah.text.length <= 500) {
        return ayah;
      }
    }

    // Default to Ayat al-Kursi (Global Number 262) or Al-Fatiha
    final ayah = await service.getAyahByGlobalNumber(262);
    if (ayah != null) return ayah;
    
    final fallback = await service.getAyahByGlobalNumber(1);
    return fallback!;
  } catch (e) {
    debugPrint('featuredAyahProvider error: $e');
    return Ayah(
      number: 1, 
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', 
      numberInSurah: 1, 
      juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, 
      surahNumber: 1, surahName: 'Al-Faatiha'
    );
  }
});

final currentThumunIndexProvider = StateProvider<int>((ref) => 1);

/// Tracks the surah being navigated to for Hero animations
final selectedSurahNumberProvider = StateProvider<int?>((ref) => null);

/// Stores a global ayah number to scroll to when navigating to MushafView.
/// This is used to ensure we land exactly on the requested surah or verse.
final targetAyahGlobalNumberProvider = StateProvider<int?>((ref) => null);

/// Used to prevent the optimistic UI from being immediately overwritten by the player stream
final isManualToggleActiveProvider = StateProvider<bool>((ref) => false);
