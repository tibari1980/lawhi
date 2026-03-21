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
  static final Map<int, String> _assetPhoneticCache = {};
  Completer<void>? _initCompleter;
  
  // Strict connectivity tracking for Web to avoid ANY console spam
  static bool _networkDisabled = false;
  static DateTime? _lastRequest;

  // Local static fallbacks to provide instant offline phonetics for common surahs
  static final List<Ayah> _commonFallbacks = [
    // Surah Al-Fatiha (1)
    Ayah(number: 1, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', phonetics: 'Bismillaahir Rahmaanir Raheem', numberInSurah: 1, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 2, text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', phonetics: 'Alhamdu lillaahi Rabbil \'aalameen', numberInSurah: 2, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 3, text: 'الرَّحْمَٰنِ الرَّحِيمِ', phonetics: 'Ar-Rahmaanir-Raheem', numberInSurah: 3, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 4, text: 'مَالِكِ يَوْمِ الدِّينِ', phonetics: 'Maaliki Yawmid-Deen', numberInSurah: 4, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 5, text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', phonetics: 'Iyyaaka na\'budu wa lyyaaka nasta\'een', numberInSurah: 5, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 6, text: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', phonetics: 'Ihdinas-Siraatal-Mustaqeem', numberInSurah: 6, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    Ayah(number: 7, text: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', phonetics: 'Siraatal-lazeena an\'amta \'alaihim ghayril-maghdoobi \'alaihim wa lad-daaalleen', numberInSurah: 7, juz: 1, manzil: 1, page: 1, ruku: 1, hizbQuarter: 1, surahNumber: 1, surahName: 'Al-Faatiha'),
    // Surah Al-Baqarah (2) - First 5 Ayahs
    Ayah(number: 8, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ الم', phonetics: 'Bismillaahir Rahmaanir Raheem. Alif-Laam-Meem', numberInSurah: 1, juz: 1, manzil: 1, page: 2, ruku: 1, hizbQuarter: 1, surahNumber: 2, surahName: 'Al-Baqarah'),
    Ayah(number: 9, text: 'ذَٰلِكَ الْكِتَابُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِلْمُتَّقِينَ', phonetics: 'Zaalikal Kitaabu laa raiba feeh; hudal lilmuttaqeen', numberInSurah: 2, juz: 1, manzil: 1, page: 2, ruku: 1, hizbQuarter: 1, surahNumber: 2, surahName: 'Al-Baqarah'),
    Ayah(number: 10, text: 'الَّذِينَ يُؤْمِنُونَ بِالْغَيْبِ وَيُقِيمُونَ الصَّلَاةَ وَمِمَّا رَزَقْنَاهُمْ يُنْفِقُونَ', phonetics: 'Allazeena yu\'minoona bilghaibi wa yuqeemoonas Salaata wa mimmaa razaqnaahum yunfiqoon', numberInSurah: 3, juz: 1, manzil: 1, page: 2, ruku: 1, hizbQuarter: 1, surahNumber: 2, surahName: 'Al-Baqarah'),
    Ayah(number: 11, text: 'وَالَّذِينَ يُؤْمِنُونَ بِمَا أُنْزِلَ إِلَيْكَ وَمَا أُنْزِلَ مِنْ قَبْلِكَ وَبِالْآخِرَةِ هُمْ يُوقِنُونَ', phonetics: 'Wallazeena yu\'minoona bimaaa onzila ilaika wa maaa onzila min qablika wa bil Aakhirati hum yooqinoon', numberInSurah: 4, juz: 1, manzil: 1, page: 2, ruku: 1, hizbQuarter: 1, surahNumber: 2, surahName: 'Al-Baqarah'),
    Ayah(number: 12, text: 'أُولَٰئِكَ عَلَىٰ هُدًى مِنْ رَبِّهِمْ ۖ وَأُولَٰئِكَ هُمُ الْمُفْلِحُونَ', phonetics: 'Olaaa\'ika \'alaa hudam mir Rabbihim wa olaaa\'ika humul muflihoon', numberInSurah: 5, juz: 1, manzil: 1, page: 2, ruku: 1, hizbQuarter: 1, surahNumber: 2, surahName: 'Al-Baqarah'),
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
    if (_assetQuranCache.isNotEmpty && _assetPhoneticCache.isNotEmpty) return;
    if (_initCompleter != null) return _initCompleter!.future;
    
    _initCompleter = Completer<void>();
    try {
      // Load Arabic text
      final String jsonStr = await rootBundle.loadString('assets/quran/ara-quran.json');
      if (jsonStr.isEmpty) throw Exception('Asset file is empty');
      
      final Map<int, List<Ayah>> tempCache = await compute(_parseAssetJson, jsonStr);
      
      // Load Phonetics
      String phoneticStr = '';
      try {
        phoneticStr = await rootBundle.loadString('assets/quran/en-transliteration.json');
      } catch (e) {
        debugPrint('Phonetic Asset Load Error: $e');
      }
      
      if (phoneticStr.isNotEmpty) {
        final Map<int, String> tempPhoneticCache = await compute(_parsePhoneticJson, phoneticStr);
        _assetPhoneticCache.clear();
        _assetPhoneticCache.addAll(tempPhoneticCache);
      }

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

  /// Static helper for [compute] to parse Phonetic JSON
  static Map<int, String> _parsePhoneticJson(String jsonStr) {
    final Map<String, dynamic> data = json.decode(jsonStr);
    final List<dynamic> surahs = data['data']['surahs'];
    final Map<int, String> results = {};
    
    for (var s in surahs) {
      final List<dynamic> ayahs = s['ayahs'];
      for (var a in ayahs) {
        results[a['number']] = a['text'];
      }
    }
    return results;
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
    final ayahs = _assetQuranCache[quarterNumber] ?? [];
    return ayahs.map((a) => a.copyWith(
      phonetics: a.phonetics ?? _assetPhoneticCache[a.number]
    )).toList();
  }

  Future<List<Ayah>> _getSurahFromAssets(int surahNumber) async {
    await initialize();
    final List<Ayah> results = [];
    for (var quarter in _assetQuranCache.values) {
      results.addAll(quarter.where((a) => a.surahNumber == surahNumber));
    }
    // Sort to ensure correct text order
    results.sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah));
    
    return results.map((a) => a.copyWith(
      phonetics: a.phonetics ?? _assetPhoneticCache[a.number]
    )).toList();
  }

  Future<Ayah?> getAyahByGlobalNumber(int number) async {
    await initialize();
    for (var quarter in _assetQuranCache.values) {
      for (var ayah in quarter) {
        if (ayah.number == number) {
          return ayah.copyWith(
            phonetics: ayah.phonetics ?? _assetPhoneticCache[ayah.number]
          );
        }
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

    if (kIsWeb && _networkDisabled) return _fallbackToAssetSurahs();

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
    } catch (e) {
      if (kIsWeb) _networkDisabled = true;
    }
    
    return _fallbackToAssetSurahs();
  }

  Future<List<Surah>> _fallbackToAssetSurahs() async {
    const cacheKey = 'surahs';
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

  Future<List<Ayah>> getSurahAyahs(int surahNumber, Riwaya riwaya, {bool includePhonetics = false}) async {
    // Web optimization: Priority to assets if phonetics are not needed
    if (kIsWeb && !includePhonetics) return _getSurahFromAssets(surahNumber);

    // Fatiha starts the app, so we give it priority fallback to avoid spinners
    if (surahNumber == 1) {
      try {
        final online = await _getSurahResilient(surahNumber, riwaya, includePhonetics: includePhonetics);
        if (online.isNotEmpty) return online;
      } catch (e) { return _commonFallbacks.where((a) => a.surahNumber == surahNumber).toList(); }
    }
    return _getSurahResilient(surahNumber, riwaya, includePhonetics: includePhonetics);
  }

  Future<List<Ayah>> _getSurahResilient(int surahNumber, Riwaya riwaya, {bool includePhonetics = false}) async {
    try {
      return await _getSurahOnline(surahNumber, riwaya, includePhonetics: includePhonetics);
    } catch (e) {
      // Final fallback to assets
      return _getSurahFromAssets(surahNumber);
    }
  }

  Future<List<Ayah>> _getSurahOnline(int surahNumber, Riwaya riwaya, {bool includePhonetics = false}) async {
    final edition = getEdition(riwaya);
    final cacheKey = 'surah_${surahNumber}_$edition';
    
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey] as List<Ayah>;
      // If phonetics are needed but missing in local cache, force API fetch
      final hasPhonetics = cached.any((a) => a.phonetics != null);
      if (!includePhonetics || hasPhonetics) return cached;
    }

    final localData = await _readFromLocal(cacheKey);
    if (localData != null) {
      final ayahs = (localData as List).map((a) => Ayah.fromJson(a)).toList();
      // If phonetics are needed but missing in local storage, only use if offline or force re-fetch
      final hasPhonetics = ayahs.any((a) => a.phonetics != null);
      
      if (!includePhonetics || hasPhonetics) {
        _memoryCache[cacheKey] = ayahs;
        return ayahs;
      }
    }

    try {
      final results = await _fetchEditionsIndividually('surah/$surahNumber', edition);
      if (results.isNotEmpty) {
        _memoryCache[cacheKey] = results;
        await _writeToLocal(cacheKey, results.map((a) => a.toJson()).toList());
        return results;
      }
    } catch (e) { /* ignore */ }

    if (riwaya == Riwaya.warsh) {
      // If Warsh fails, fallback to Hafs before fully giving up to assets
      return getSurahAyahs(surahNumber, Riwaya.hafs);
    }
    
    throw Exception('Failed to load surah $surahNumber');
  }

  Future<List<Ayah>> getHizbQuarterAyahs(int quarterNumber, Riwaya riwaya, {bool includePhonetics = false}) async {
    // Web optimization: Priority to assets if phonetics are not needed
    if (kIsWeb && !includePhonetics) return _getQuarterFromAssets(quarterNumber);

    if (quarterNumber == 1) {
      try {
        final online = await _getQuarterResilient(quarterNumber, riwaya, includePhonetics: includePhonetics);
        if (online.isNotEmpty) return online;
      } catch (e) { return _commonFallbacks.where((a) => a.hizbQuarter == quarterNumber).toList(); }
    }
    return _getQuarterResilient(quarterNumber, riwaya, includePhonetics: includePhonetics);
  }

  Future<List<Ayah>> _getQuarterResilient(int quarterNumber, Riwaya riwaya, {bool includePhonetics = false}) async {
    try {
      return await _getQuarterOnline(quarterNumber, riwaya, includePhonetics: includePhonetics);
    } catch (e) {
      return _getQuarterFromAssets(quarterNumber);
    }
  }

  Future<List<Ayah>> _getQuarterOnline(int quarterNumber, Riwaya riwaya, {bool includePhonetics = false}) async {
    final edition = getEdition(riwaya);
    final cacheKey = 'quarter_${quarterNumber}_$edition';
    
    if (_quarterCache.containsKey(cacheKey)) {
      final cached = _quarterCache[cacheKey]!;
      final hasPhonetics = cached.any((a) => a.phonetics != null);
      if (!includePhonetics || hasPhonetics) return cached;
    }

    final localData = await _readFromLocal(cacheKey);
    if (localData != null) {
      final ayahs = (localData as List).map((a) => Ayah.fromJson(a)).toList();
      final hasPhonetics = ayahs.any((a) => a.phonetics != null);
      
      if (!includePhonetics || hasPhonetics) {
        _quarterCache[cacheKey] = ayahs;
        return ayahs;
      }
    }

    // Note: Al-Quran Cloud does NOT support the /editions/ combined endpoint for hizbQuarter (returns 500)
    // We must fetch editions individually for quarters
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
    // 1. Absolute network block for Web if session had a failure
    if (kIsWeb && _networkDisabled) return []; 

    try {
      // Throttle requests on Web to avoid 429
      if (kIsWeb) {
        final now = DateTime.now();
        if (_lastRequest != null && now.difference(_lastRequest!).inMilliseconds < 1500) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
        _lastRequest = DateTime.now();
      }

      // ... existing code ...

      // 1. Fetch Arabic (base) - Try assets first on Web to avoid CORS spam
      List<Ayah> results = [];
      if (kIsWeb) {
        if (path.startsWith('surah/')) {
          results = await _getSurahFromAssets(int.parse(path.split('/').last));
        } else if (path.startsWith('hizbQuarter/')) {
          results = await _getQuarterFromAssets(int.parse(path.split('/').last));
        }
      }

      if (results.isEmpty) {
        if (kIsWeb && _networkDisabled) return [];
        
        try {
          final arabicResponse = await http.get(Uri.parse('$baseUrl/$path/$arabicEdition'))
              .timeout(const Duration(seconds: 10));
          
          if (arabicResponse.statusCode != 200) {
            final simpleResponse = await http.get(Uri.parse('$baseUrl/$path/quran-simple'))
                .timeout(const Duration(seconds: 10));
            if (simpleResponse.statusCode != 200) return [];
            return _mergeSingleWithDefaults(simpleResponse.body);
          }
          results = _mergeSingleWithDefaults(arabicResponse.body);
        } catch (e) {
          if (kIsWeb) _networkDisabled = true;
          return [];
        }
      }

      if (results.isEmpty) return [];

      // Stop fetching additional editions (French/English translations) to lighten the app
      
      // Merge results with offline phonetics
      for (int i = 0; i < results.length; i++) {
        final a = results[i];
        final phonetics = _assetPhoneticCache[a.number];
        
        results[i] = a.copyWith(
          phonetics: phonetics ?? a.phonetics,
        );
      }

      // If we got here successfully, we are online
      if (kIsWeb) _networkDisabled = false;

      return results;
    } catch (e) { 
      // Detect network failure to stop ALL console spam for the rest of the session
      if (kIsWeb) _networkDisabled = true;
      return []; 
    }
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
