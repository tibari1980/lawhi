import 'dart:io';
import 'package:just_audio/just_audio.dart';

AudioSource createPlatformAudioSource(String url, String cachePath) {
  // ignore: experimental_member_use
  return LockCachingAudioSource(Uri.parse(url), cacheFile: File(cachePath));
}
