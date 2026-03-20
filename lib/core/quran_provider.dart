import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  List<Ayah> _playlistAyahs = [];

  bool _isManuallySeeking = false;

  AudioNotifier(this.ref) : super(null) {
    _setupListener();
  }

  void _setupListener() {
    _indexSubscription?.cancel();
    _indexSubscription = ref.read(audioServiceProvider).currentIndexStream.listen((index) {
      if (_isManuallySeeking) return; // Ignore updates during manual seek
      
      if (index != null && index >= 0 && index < _playlistAyahs.length) {
        final newAyah = _playlistAyahs[index];
        if (state?.number != newAyah.number) {
          state = newAyah;
          _announceAyah(newAyah);
        }
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

  void _preCacheSurah(List<Ayah> ayahs) {
    if (ayahs.isEmpty) return;
    // Fire and forget caching to prepare for potential Airplane mode
    ref.read(audioServiceProvider).preCacheSurah(ayahs);
  }

  Future<void> playNext() async {
    final audioService = ref.read(audioServiceProvider);
    // Since we use ConcatenatingAudioSource, just seek to next
    // The player will emit a new index which we listen to
    await audioService.seekToIndex((_playlistAyahs.indexWhere((a) => a.number == (state?.number ?? -1))) + 1);
  }

  Future<void> playPrevious() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.seekToIndex((_playlistAyahs.indexWhere((a) => a.number == (state?.number ?? -1))) - 1);
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
    super.dispose();
  }
}

final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final service = ref.watch(quranServiceProvider);
  return service.getSurahs();
});

final surahAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, surahNumber) async {
  final service = ref.watch(quranServiceProvider);
  final riwaya = ref.watch(settingsProvider.select((s) => s.riwaya));
  return service.getSurahAyahs(surahNumber, riwaya);
});

final hizbQuarterAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, quarterNumber) async {
  final service = ref.watch(quranServiceProvider);
  final riwaya = ref.watch(settingsProvider.select((s) => s.riwaya));
  return service.getHizbQuarterAyahs(quarterNumber, riwaya);
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
  try {
    // Default to Ayat al-Kursi (Global Number 262)
    final ayah = await service.getAyahByGlobalNumber(262);
    if (ayah != null) return ayah;
    
    // Fallback to Al-Fatiha Ayah 1 (Global 1) if not found
    final fallback = await service.getAyahByGlobalNumber(1);
    return fallback!;
  } catch (e) {
    // Ultimate hardcoded fallback to ensure no crash
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
