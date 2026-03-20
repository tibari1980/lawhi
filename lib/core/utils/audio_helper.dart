import 'package:just_audio/just_audio.dart';
import 'audio_helper_mobile.dart' if (dart.library.html) 'audio_helper_web.dart';

class AudioHelper {
  static AudioSource createAudioSource(String url, String cachePath) {
    return createPlatformAudioSource(url, cachePath);
  }
}
