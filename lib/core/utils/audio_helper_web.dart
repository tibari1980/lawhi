import 'package:just_audio/just_audio.dart';

AudioSource createPlatformAudioSource(String url, String cachePath) {
  return AudioSource.uri(Uri.parse(url));
}
