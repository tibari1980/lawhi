import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/doua_content.dart';

class AudioSyncService {
  static final AudioSyncService _instance = AudioSyncService._internal();
  factory AudioSyncService() => _instance;
  AudioSyncService._internal();

  final ValueNotifier<bool> isSyncComplete = ValueNotifier(false);
  bool _isSyncing = false;

  Future<void> preDownloadAll() async {
    if (kIsWeb || _isSyncing) return;
    _isSyncing = true;
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final adkarDir = Directory(p.join(cacheDir.path, 'adkar_cache'));
      if (!await adkarDir.exists()) await adkarDir.create(recursive: true);

      await Future.wait([
        _downloadIfMissing(DouaContent.sabahAudioUrl, p.join(adkarDir.path, 'sabah.mp3')),
        _downloadIfMissing(DouaContent.masaaAudioUrl, p.join(adkarDir.path, 'masaa.mp3')),
        _downloadIfMissing(DouaContent.khatmAudioUrl, p.join(adkarDir.path, 'khatm.mp3')),
      ]);
      isSyncComplete.value = true;
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _downloadIfMissing(String url, String localPath) async {
    final file = File(localPath);
    if (await file.exists()) return;

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      }
    } catch (_) {
    }
  }

  Future<String?> getLocalPath(String type) async {
    if (kIsWeb) return null;
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final path = p.join(cacheDir.path, 'adkar_cache', '$type.mp3');
      if (await File(path).exists()) return path;
    } catch (_) {}
    return null;
  }
}
