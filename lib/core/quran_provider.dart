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

final hizbQuarterAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, quarterNumber) async {
  final service = ref.watch(quranServiceProvider);
  return service.getHizbQuarterAyahs(quarterNumber);
});

final thumunAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, thumunIndex) async {
  final quarterIndex = ((thumunIndex - 1) / 2).floor() + 1;
  final isFirstThumun = (thumunIndex - 1) % 2 == 0;
  
  final ayahs = await ref.watch(hizbQuarterAyahsProvider(quarterIndex).future);
  
  // Pre-fetch next quarter if we are nearing the end of current one
  if (thumunIndex < 480) {
    final nextQuarter = ((thumunIndex) / 2).floor() + 1;
    if (nextQuarter != quarterIndex) {
      ref.read(hizbQuarterAyahsProvider(nextQuarter));
    }
  }

  final midPoint = (ayahs.length / 2).floor();
  return isFirstThumun ? ayahs.sublist(0, midPoint) : ayahs.sublist(midPoint);
});

final hizbFirstAyahProvider = FutureProvider.family<Ayah, int>((ref, hizbNumber) async {
  final startQuarter = (hizbNumber - 1) * 4 + 1;
  final ayahs = await ref.watch(hizbQuarterAyahsProvider(startQuarter).future);
  return ayahs.first;
});

// Providers for home page stats
final lastReadProvider = StateProvider<String>((ref) => 'سورة البقرة • آية 15');
final favoritesCountProvider = StateProvider<int>((ref) => 5);
final currentThumunIndexProvider = StateProvider<int>((ref) => 1);
