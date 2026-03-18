import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void main() async {
  // Check the first quarter of Hizb 1
  final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/hizbQuarter/1/quran-simple'));
  if (response.statusCode == 200) {
    final data = json.decode(response.body)['data']['ayahs'];
    debugPrint('Quarter 1 has ${data.length} ayahs');
    for (var i = 0; i < data.length; i++) {
      debugPrint('Ayah ${i+1}: Surah ${data[i]['surah']['number']}, Ayah ${data[i]['numberInSurah']}');
    }
  } else {
    debugPrint('Failed to load');
  }
}
