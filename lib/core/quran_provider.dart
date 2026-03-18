import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/quran_service.dart';
import 'models/quran_models.dart';

final quranServiceProvider = Provider((ref) => QuranService());

final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final service = ref.watch(quranServiceProvider);
  return service.getSurahs();
});

final surahAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, surahNumber) async {
  final service = ref.watch(quranServiceProvider);
  return service.getSurahAyahs(surahNumber);
});

final hizbAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, hizbNumber) async {
  final service = ref.watch(quranServiceProvider);
  return service.getHizbAyahs(hizbNumber);
});

final hizbFirstAyahProvider = FutureProvider.family<Ayah, int>((ref, hizbNumber) async {
  final service = ref.watch(quranServiceProvider);
  final startQuarter = (hizbNumber - 1) * 4 + 1;
  final ayahs = await service.getHizbQuarterAyahs(startQuarter);
  return ayahs.first;
});

// Providers for home page stats
final lastReadProvider = StateProvider<String>((ref) => 'سورة البقرة • آية 15');
final favoritesCountProvider = StateProvider<int>((ref) => 5);
