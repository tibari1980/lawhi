import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/quran_models.dart';

class QuranService {
  final String baseUrl = 'https://api.alquran.cloud/v1';
  
  String getEdition(Riwaya riwaya) {
    return riwaya == Riwaya.warsh ? 'ara-quranwarsh' : 'quran-uthmani';
  }
  
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, List<Ayah>> _quarterCache = {};
  static final Map<int, List<Ayah>> _assetQuranCache = {};
  Completer<void>? _initCompleter;

  // Local static fallback for Al-Fatiha to avoid any loading delay for the first page
  static final List<Ayah> _fatihaFallback = [
    Ayah(number: 1, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', numberInSurah: 1, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 2, text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', numberInSurah: 2, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 3, text: 'الرَّحْمَٰنِ الرَّحِيمِ', numberInSurah: 3, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 4, text: 'مَالِكِ يَوْمِ الدِّينِ', numberInSurah: 4, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 5, text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', numberInSurah: 5, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 6, text: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', numberInSurah: 6, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 7, text: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', numberInSurah: 7, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
  ];

  // --- Persistence Logic ---

  Future<dynamic> _getCacheFile(String fileName) async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/quran_cache';
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return File('$path/$fileName.json');
    } catch (e) {
      return null;
    }
  }

  Future<void> _writeToLocal(String fileName, dynamic data) async {
    if (kIsWeb) return;
    try {
      final file = await _getCacheFile(fileName);
      if (file is File) {
        await file.writeAsString(json.encode(data));
      }
    } catch (e) { /* ignore */ }
  }

  Future<dynamic> _readFromLocal(String fileName) async {
    if (kIsWeb) return null;
    try {
      final file = await _getCacheFile(fileName);
      if (file is File && await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content);
      }
    } catch (e) { /* ignore */ }
    return null;
  }

  // --- Asset Fallback Logic ---

  /// Prepares the in-memory cache from bundled assets.
  /// Uses [compute] to offload heavy JSON parsing to a separate isolate,
  /// keeping the UI thread (and splash screen) fluid.
  Future<void> initialize() async {
    if (_assetQuranCache.isNotEmpty) return;
    if (_initCompleter != null) return _initCompleter!.future;
    
    _initCompleter = Completer<void>();
    try {
      final String jsonStr = await rootBundle.loadString('assets/quran/ara-quran.json');
      if (jsonStr.isEmpty) throw Exception('Asset file is empty');
      
      final Map<int, List<Ayah>> tempCache = await compute(_parseAssetJson, jsonStr);
      
      if (tempCache.isEmpty) throw Exception('No quarters mapped from asset');
      _assetQuranCache.clear();
      _assetQuranCache.addAll(tempCache);
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      debugPrint('Asset Fallback Error: $e');
    }
  }

  /// Static helper for [compute] to parse large Quran JSON
  static Map<int, List<Ayah>> _parseAssetJson(String jsonStr) {
    final Map<String, dynamic> data = json.decode(jsonStr);
    final List<dynamic> surahs = data['data']['surahs'];
    final Map<int, List<Ayah>> results = {};
    
    for (var s in surahs) {
      final int sNum = s['number'];
      final String sName = s['name'];
      final List<dynamic> ayahs = s['ayahs'];
      
      for (var a in ayahs) {
        final int q = a['hizbQuarter'] ?? 0;
        if (q == 0) continue;
        
        final ayah = Ayah.fromJson({
          ...a,
          'surah': {'number': sNum, 'name': sName}
        });
        results[q] = (results[q] ?? [])..add(ayah);
      }
    }
    return results;
  }

  Future<List<Ayah>> _getQuarterFromAssets(int quarterNumber) async {
    await initialize();
    return _assetQuranCache[quarterNumber] ?? [];
  }

  Future<List<Ayah>> _getSurahFromAssets(int surahNumber) async {
    await initialize();
    final List<Ayah> results = [];
    for (var quarter in _assetQuranCache.values) {
      results.addAll(quarter.where((a) => a.surahNumber == surahNumber));
    }
    // Sort to ensure correct text order
    results.sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah));
    return results;
  }

  Future<Ayah?> getAyahByGlobalNumber(int number) async {
    await initialize();
    for (var quarter in _assetQuranCache.values) {
      for (var ayah in quarter) {
        if (ayah.number == number) return ayah;
      }
    }
    return null;
  }

  // --- API Methods ---

  Future<List<Surah>> getSurahs() async {
    const cacheKey = 'surahs';
    if (_memoryCache.containsKey(cacheKey)) return _memoryCache[cacheKey] as List<Surah>;

    final localData = await _readFromLocal(cacheKey);
    if (localData != null) {
      final surahs = (localData as List).map((surah) => Surah.fromJson(surah)).toList();
      _memoryCache[cacheKey] = surahs;
      return surahs;
    }

    if (kIsWeb) {
      // Direct asset load on web for speed and clean console
      await initialize();
      final String jsonStr = await rootBundle.loadString('assets/quran/ara-quran.json');
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List<dynamic> surahsData = data['data']['surahs'];
      final surahs = surahsData.map((s) => Surah.fromJson({
        'number': s['number'],
        'name': s['name'],
        'englishName': s['englishName'] ?? 'Surah ${s['number']}',
        'englishNameTranslation': s['englishNameTranslation'] ?? '',
        'numberOfAyahs': (s['ayahs'] as List).length,
        'revelationType': s['revelationType'] ?? 'Meccan',
      })).toList();
      _memoryCache[cacheKey] = surahs;
      return surahs;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/surah'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        final surahs = data.map((surah) => Surah.fromJson(surah)).toList();
        _memoryCache[cacheKey] = surahs;
        await _writeToLocal(cacheKey, data);
        return surahs;
      }
    } catch (e) { /* ignore */ }
    
    // Quick fallback
    await initialize();
    final String jsonStr = await rootBundle.loadString('assets/quran/ara-quran.json');
    final Map<String, dynamic> data = json.decode(jsonStr);
    final List<dynamic> surahsData = data['data']['surahs'];
    final surahs = surahsData.map((s) => Surah.fromJson({
      'number': s['number'],
      'name': s['name'],
      'englishName': s['englishName'] ?? 'Surah ${s['number']}',
      'englishNameTranslation': s['englishNameTranslation'] ?? '',
      'numberOfAyahs': (s['ayahs'] as List).length,
      'revelationType': s['revelationType'] ?? 'Meccan',
    })).toList();
    _memoryCache[cacheKey] = surahs;
    return surahs;
  }

  Future<List<Ayah>> getSurahAyahs(int surahNumber, Riwaya riwaya) async {
    if (kIsWeb) return _getSurahFromAssets(surahNumber);
    
    // Fatiha starts the app, so we give it priority fallback to avoid spinners
    if (surahNumber == 1) {
      try {
        final online = await _getSurahResilient(surahNumber, riwaya);
        if (online.isNotEmpty) return online;
      } catch (e) { return _fatihaFallback; }
    }
    return _getSurahResilient(surahNumber, riwaya);
  }

  Future<List<Ayah>> _getSurahResilient(int surahNumber, Riwaya riwaya) async {
    if (kIsWeb) {
      // On web, skip network to avoid CORS console errors and provide instant load
      return _getSurahFromAssets(surahNumber);
    }
    try {
      return await _getSurahOnline(surahNumber, riwaya);
    } catch (e) {
      // Final fallback to assets
      return _getSurahFromAssets(surahNumber);
    }
  }

  Future<List<Ayah>> _getSurahOnline(int surahNumber, Riwaya riwaya) async {
    if (kIsWeb) return []; // Block network requests on web
    final edition = getEdition(riwaya);
    final cacheKey = 'surah_${surahNumber}_$edition';
    if (_memoryCache.containsKey(cacheKey)) return _memoryCache[cacheKey] as List<Ayah>;

    final localData = await _readFromLocal(cacheKey);
    if (localData != null) {
      final ayahs = (localData as List).map((a) => Ayah.fromJson(a)).toList();
      _memoryCache[cacheKey] = ayahs;
      return ayahs;
    }

    try {
      final editions = '$edition,fr.hamidullah,en.sahih,en.transliteration';
      final response = await http.get(Uri.parse('$baseUrl/surah/$surahNumber/editions/$editions'))
          .timeout(Duration(seconds: kIsWeb ? 2 : 15));
      if (response.statusCode == 200) {
        final ayahs = _parseMultiEditionAyahs(response.body);
        if (ayahs.isNotEmpty) {
          _memoryCache[cacheKey] = ayahs;
          await _writeToLocal(cacheKey, ayahs.map((a) => a.toJson()).toList());
          return ayahs;
        }
      }
    } catch (e) { /* ignore */ }

    final results = await _fetchEditionsIndividually('surah/$surahNumber', edition);
    if (results.isNotEmpty) {
      _memoryCache[cacheKey] = results;
      await _writeToLocal(cacheKey, results.map((a) => a.toJson()).toList());
      return results;
    }

    if (riwaya == Riwaya.warsh) {
      // If Warsh fails, fallback to Hafs before fully giving up to assets
      return getSurahAyahs(surahNumber, Riwaya.hafs);
    }
    
    throw Exception('Failed to load surah $surahNumber');
  }

  Future<List<Ayah>> getHizbQuarterAyahs(int quarterNumber, Riwaya riwaya) async {
    if (kIsWeb) return _getQuarterFromAssets(quarterNumber);
    
    if (quarterNumber == 1) {
      try {
        final online = await _getQuarterResilient(quarterNumber, riwaya);
        if (online.isNotEmpty) return online;
      } catch (e) { return _fatihaFallback; }
    }
    return _getQuarterResilient(quarterNumber, riwaya);
  }

  Future<List<Ayah>> _getQuarterResilient(int quarterNumber, Riwaya riwaya) async {
    if (kIsWeb) {
      // Local asset only on web to silence CORS console spam
      return _getQuarterFromAssets(quarterNumber);
    }
    try {
      return await _getQuarterOnline(quarterNumber, riwaya);
    } catch (e) {
      return _getQuarterFromAssets(quarterNumber);
    }
  }

  Future<List<Ayah>> _getQuarterOnline(int quarterNumber, Riwaya riwaya) async {
    if (kIsWeb) return []; // Block network requests on web
    final edition = getEdition(riwaya);
    final cacheKey = 'quarter_${quarterNumber}_$edition';
    if (_quarterCache.containsKey(cacheKey)) return _quarterCache[cacheKey]!;

    final localData = await _readFromLocal(cacheKey);
    if (localData != null) {
      final ayahs = (localData as List).map((a) => Ayah.fromJson(a)).toList();
      _quarterCache[cacheKey] = ayahs;
      return ayahs;
    }

    try {
      final editions = '$edition,fr.hamidullah,en.sahih,en.transliteration';
      final response = await http.get(Uri.parse('$baseUrl/hizbQuarter/$quarterNumber/editions/$editions'))
          .timeout(Duration(seconds: kIsWeb ? 2 : 15));
      if (response.statusCode == 200) {
        final ayahs = _parseMultiEditionAyahs(response.body);
        if (ayahs.isNotEmpty) {
          _quarterCache[cacheKey] = ayahs;
          await _writeToLocal(cacheKey, ayahs.map((a) => a.toJson()).toList());
          return ayahs;
        }
      }
    } catch (e) { /* ignore */ }

    final results = await _fetchEditionsIndividually('hizbQuarter/$quarterNumber', edition);
    if (results.isNotEmpty) {
      _quarterCache[cacheKey] = results;
      await _writeToLocal(cacheKey, results.map((a) => a.toJson()).toList());
      return results;
    }

    if (riwaya == Riwaya.warsh) {
      return getHizbQuarterAyahs(quarterNumber, Riwaya.hafs);
    }

    throw Exception('Failed to load quarter $quarterNumber');
  }

  Future<List<Ayah>> _fetchEditionsIndividually(String path, String arabicEdition) async {
    if (kIsWeb) return []; // Double safety
    try {
      final arabicResponse = await http.get(Uri.parse('$baseUrl/$path/$arabicEdition'))
          .timeout(const Duration(seconds: 10));
      
      if (arabicResponse.statusCode != 200) {
        final simpleResponse = await http.get(Uri.parse('$baseUrl/$path/quran-simple'))
            .timeout(const Duration(seconds: 10));
        if (simpleResponse.statusCode != 200) return [];
        return _mergeSingleWithDefaults(simpleResponse.body);
      }

      final otherResponses = await Future.wait([
        http.get(Uri.parse('$baseUrl/$path/fr.hamidullah')).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('', 404)),
        http.get(Uri.parse('$baseUrl/$path/en.sahih')).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('', 404)),
        http.get(Uri.parse('$baseUrl/$path/en.transliteration')).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('', 404)),
      ]);

      return _mergeResponses(arabicResponse, otherResponses);
    } catch (e) { return []; }
  }

  List<Ayah> _parseMultiEditionAyahs(String body) {
    try {
      final jsonResponse = json.decode(body);
      final List<dynamic> data = jsonResponse['data'];
      if (data.isEmpty) return [];

      final mainAyahs = data[0]['ayahs'];
      final List<dynamic> frenchAyahs = data.length > 1 ? data[1]['ayahs'] : [];
      final List<dynamic> englishAyahs = data.length > 2 ? data[2]['ayahs'] : [];
      final List<dynamic> phoneticsAyahs = data.length > 3 ? data[3]['ayahs'] : [];
      
      final String surahName = data[0]['name'];
      final int surahNumber = data[0]['number'];

      final List<Ayah> ayahs = [];
      for (int i = 0; i < mainAyahs.length; i++) {
        String translation = '';
        if (i < frenchAyahs.length && i < englishAyahs.length) {
          translation = '${frenchAyahs[i]['text']}|||${englishAyahs[i]['text']}';
        } else if (i < frenchAyahs.length) {
          translation = frenchAyahs[i]['text'];
        }
        String? phonetics = i < phoneticsAyahs.length ? phoneticsAyahs[i]['text'] : null;
        ayahs.add(Ayah.fromJson(
          mainAyahs[i], 
          translation: translation, 
          phonetics: phonetics,
          surahNumber: surahNumber,
          surahName: surahName,
        ));
      }
      return ayahs;
    } catch (e) { return []; }
  }

  List<Ayah> _mergeResponses(http.Response arabic, List<http.Response> others) {
    try {
      final mainResponse = json.decode(arabic.body)['data'];
      final mainData = mainResponse['ayahs'];
      final String surahName = mainResponse['name'];
      final int surahNumber = mainResponse['number'];

      final List<dynamic> frenchData = others[0].statusCode == 200 ? json.decode(others[0].body)['data']['ayahs'] : [];
      final List<dynamic> englishData = others[1].statusCode == 200 ? json.decode(others[1].body)['data']['ayahs'] : [];
      final List<dynamic> phoneticsData = others[2].statusCode == 200 ? json.decode(others[2].body)['data']['ayahs'] : [];

      final List<Ayah> ayahs = [];
      for (int i = 0; i < mainData.length; i++) {
        String translation = '';
        if (i < frenchData.length && i < englishData.length) {
          translation = '${frenchData[i]['text']}|||${englishData[i]['text']}';
        } else if (i < frenchData.length) {
          translation = frenchData[i]['text'];
        }
        String? phonetics = i < phoneticsData.length ? phoneticsData[i]['text'] : null;
        ayahs.add(Ayah.fromJson(
          mainData[i], 
          translation: translation, 
          phonetics: phonetics,
          surahNumber: surahNumber,
          surahName: surahName,
        ));
      }
      return ayahs;
    } catch (e) { return []; }
  }

  List<Ayah> _mergeSingleWithDefaults(String body) {
    try {
      final mainData = json.decode(body)['data']['ayahs'];
      final List<Ayah> ayahs = [];
      for (var item in mainData) {
        ayahs.add(Ayah.fromJson(item));
      }
      return ayahs;
    } catch (e) { return []; }
  }
}
