import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/quran_provider.dart';
import '../mushaf/mushaf_page.dart';
import '../../core/widgets/error_view.dart';

class SuwarView extends ConsumerWidget {
  const SuwarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsyncValue = ref.watch(surahsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: surahsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
        error: (err, stack) => CustomErrorView(
          title: 'خطأ في تحميل السور',
          message: 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
          onRetry: () => ref.refresh(surahsProvider),
        ),
        data: (surahs) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return Semantics(
                label: 'سورة ${surah.name}, ${surah.englishName}, ${surah.numberOfAyahs} آية',
                button: true,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    onTap: () {
                      // Navigate to MushafPage with this surah
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MushafViewWithData(
                            title: 'سورة ${surah.name}',
                            surahNumber: surah.number,
                          ),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      surah.name,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    subtitle: Text(
                      '${surah.englishName} • ${surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'} • ${surah.numberOfAyahs} آية',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Text(
                        '${surah.number}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MushafViewWithData extends ConsumerWidget {
  final String title;
  final int surahNumber;

  const MushafViewWithData({
    super.key,
    required this.title,
    required this.surahNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahsAsyncValue = ref.watch(surahAyahsProvider(surahNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ayahsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
        error: (err, stack) => CustomErrorView(
          title: 'فشل تحميل الآيات',
          message: 'حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة لاحقاً.',
          onRetry: () => ref.refresh(surahAyahsProvider(surahNumber)),
        ),
        data: (ayahs) => MushafPage(
          thumnTitle: title,
          ayahs: ayahs,
        ),
      ),
    );
  }
}
