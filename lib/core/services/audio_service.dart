import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../models/quran_models.dart';

class QuranAudioService {
  final AudioPlayer _player = AudioPlayer();
  final String _reciter = 'ar.alafasy';
  
  Ayah? _currentAyah;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  
  Ayah? get currentAyah => _currentAyah;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> playAyah(Ayah ayah) async {
    try {
      _currentAyah = ayah;
      final url = 'https://cdn.islamic.network/quran/audio/128/$_reciter/${ayah.number}.mp3';
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.play();
    } catch (e) {
      debugPrint('Error playing ayah: $e');
      rethrow;
    }
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() {
    _player.dispose();
  }
}
