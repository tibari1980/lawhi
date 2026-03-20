import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/audio_helper.dart';
import '../utils/io_utils.dart';
import '../models/quran_models.dart';

class QuranAudioService {
  final AudioPlayer _player = AudioPlayer();
  final String _reciter = 'ar.alafasy';
  
  Ayah? _currentAyah;
  ConcatenatingAudioSource? _playlist;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  
  Ayah? get currentAyah => _currentAyah;
  bool get playing => _player.playing;

  Future<void> init() async {
    if (!kIsWeb) {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
    }
  }

  Future<void> setPlaylist(List<Ayah> ayahs, {int initialIndex = 0}) async {
    
    try {
      if (_player.playing) {
        await _player.pause();
      }
      
      final bool isSingle = ayahs.length == 1;
      
      if (kIsWeb) {
        if (isSingle) {
          final url = 'https://cdn.islamic.network/quran/audio/128/$_reciter/${ayahs[0].number}.mp3';
          await _player.setAudioSource(AudioSource.uri(Uri.parse(url)), preload: false);
        } else {
          final sources = ayahs.map((ayah) {
            final url = 'https://cdn.islamic.network/quran/audio/128/$_reciter/${ayah.number}.mp3';
            return AudioSource.uri(Uri.parse(url));
          }).toList();
          _playlist = ConcatenatingAudioSource(children: sources);
          await _player.setAudioSource(_playlist!, initialIndex: initialIndex, preload: false);
        }
      } else {
        final audioCacheDir = await _getCacheDir();
        final sources = ayahs.map((ayah) {
          final url = 'https://cdn.islamic.network/quran/audio/128/$_reciter/${ayah.number}.mp3';
          final cachePath = '${audioCacheDir.path}/${ayah.number}.mp3';
          return AudioHelper.createAudioSource(url, cachePath);
        }).toList();
        
        if (isSingle) {
          await _player.setAudioSource(sources[0], preload: !kIsWeb);
        } else {
          _playlist = ConcatenatingAudioSource(children: sources);
          await _player.setAudioSource(_playlist!, initialIndex: initialIndex, preload: !kIsWeb);
        }
      }
    } catch (e) {
      debugPrint('Error setting playlist: $e');
      // On web, sometimes it fails if the file is not yet available
    }
  }

  Future<Directory> _getCacheDir() async {
    final cacheDir = await getApplicationDocumentsDirectory();
    final audioCacheDir = Directory('${cacheDir.path}/audio_cache/$_reciter');
    if (!await audioCacheDir.exists()) {
      await audioCacheDir.create(recursive: true);
    }
    return audioCacheDir;
  }

  Future<void> preCacheSurah(List<Ayah> ayahs) async {
    if (kIsWeb) return; // Web caching handled differently or not supported
    
    try {
      final audioCacheDir = await _getCacheDir();
      for (var ayah in ayahs.take(10)) { // Pre-cache first 10 immediately
        final file = File('${audioCacheDir.path}/${ayah.number}.mp3');
        if (!await file.exists()) {
          // Trigger download without waiting for playback
          // LockCachingAudioSource does this internally when playing, 
          // but we can proactively fetch if needed.
        }
      }
    } catch (e) {
      debugPrint('Pre-cache error: $e');
    }
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);
  Future<void> seekToIndex(int index) async => await _player.seek(Duration.zero, index: index);

  void dispose() {
    _player.dispose();
  }
}
