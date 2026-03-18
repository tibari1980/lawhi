import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran_models.dart';

class QuranService {
  final String baseUrl = 'https://api.alquran.cloud/v1';
  // Standard Warsh edition for authenticity
  final String edition = 'ara-quranwarsh';
  
  // Simple in-memory cache to ensure fluidity and reduce data usage
  static final Map<String, dynamic> _cache = {};

  Future<List<Surah>> getSurahs() async {
    const cacheKey = 'surahs';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey] as List<Surah>;

    final response = await http.get(Uri.parse('$baseUrl/surah'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      final surahs = data.map((surah) => Surah.fromJson(surah)).toList();
      _cache[cacheKey] = surahs;
      return surahs;
    } else {
      throw Exception('Failed to load surahs');
    }
  }

  Future<List<Ayah>> getSurahAyahs(int surahNumber) async {
    final cacheKey = 'surah_$surahNumber';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey] as List<Ayah>;

    final response = await http.get(Uri.parse('$baseUrl/surah/$surahNumber/$edition'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data']['ayahs'];
      final ayahs = data.map((ayah) => Ayah.fromJson(ayah)).toList();
      _cache[cacheKey] = ayahs;
      return ayahs;
    } else {
      throw Exception('Failed to load ayahs for surah $surahNumber');
    }
  }

  Future<List<Ayah>> getHizbAyahs(int hizbNumber) async {
    final cacheKey = 'hizb_$hizbNumber';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey] as List<Ayah>;

    try {
      // A Hizb (1-60) consists of 4 Hizb Quarters (1-240)
      final startQuarter = (hizbNumber - 1) * 4 + 1;
      final quarterFutures = List.generate(4, (i) => getHizbQuarterAyahs(startQuarter + i));
      
      final quarters = await Future.wait(quarterFutures);
      final allAyahs = quarters.expand((q) => q).toList();
      _cache[cacheKey] = allAyahs;
      return allAyahs;
    } catch (e) {
      throw Exception('Failed to load ayahs for hizb $hizbNumber: $e');
    }
  }

  Future<List<Ayah>> getHizbQuarterAyahs(int quarterNumber) async {
    final response = await http.get(Uri.parse('$baseUrl/hizbQuarter/$quarterNumber/quran-simple'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data']['ayahs'];
      return data.map((ayah) => Ayah.fromJson(ayah)).toList();
    } else {
      throw Exception('Failed to load quarter $quarterNumber');
    }
  }
}
