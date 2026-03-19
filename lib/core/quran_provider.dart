import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/painting.dart';
import 'services/quran_service.dart';
import 'services/audio_service.dart';
import 'models/quran_models.dart';
import 'settings_provider.dart';

final quranServiceProvider = Provider((ref) => QuranService());
final audioServiceProvider = Provider((ref) => QuranAudioService());
final currentPlayingAyahProvider = StateNotifierProvider<AudioNotifier, Ayah?>((ref) {
  return AudioNotifier(ref);
});

class AudioNotifier extends StateNotifier<Ayah?> {
  final Ref ref;
  bool _isListening = false;

  AudioNotifier(this.ref) : super(null);

  void _setupListener() {
    if (_isListening) return;
    _isListening = true;
    ref.read(audioServiceProvider).playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed) {
        await playNext();
      }
    });
  }

  Future<void> playAyah(Ayah ayah) async {
    state = ayah;
    _setupListener();
    await ref.read(audioServiceProvider).playAyah(ayah);
    
    // Accessibility: Haptic Feedback and Voice Announcement
    HapticFeedback.lightImpact();
    SemanticsService.announce(
      'Verset ${ayah.numberInSurah} de la sourate ${ayah.surahName}', 
      TextDirection.ltr
    );
  }

  Future<void> playNext() async {
    if (state == null) return;
    final service = ref.read(quranServiceProvider);
    final nextAyah = await service.getAyahByGlobalNumber(state!.number + 1);
    if (nextAyah != null) {
      await playAyah(nextAyah);
    }
  }

  Future<void> playPrevious() async {
    if (state == null) return;
    final service = ref.read(quranServiceProvider);
    final prevAyah = await service.getAyahByGlobalNumber(state!.number - 1);
    if (prevAyah != null) {
      await playAyah(prevAyah);
    }
  }

  Future<void> togglePlayPause() async {
    final player = ref.read(audioServiceProvider);
    
    // Check if something is actually playing or loaded
    if (state == null) return;

    final isPlaying = await player.playerStateStream.first.then((s) => s.playing);
    if (isPlaying) {
      await player.pause();
    } else {
      await player.resume();
    }
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
final currentThumunIndexProvider = StateProvider<int>((ref) => 1);

/// Tracks the surah being navigated to for Hero animations
final selectedSurahNumberProvider = StateProvider<int?>((ref) => null);

/// Stores a global ayah number to scroll to when navigating to MushafView.
/// This is used to ensure we land exactly on the requested surah or verse.
final targetAyahGlobalNumberProvider = StateProvider<int?>((ref) => null);
