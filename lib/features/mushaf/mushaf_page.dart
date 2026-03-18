import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings_provider.dart';
import '../../core/models/quran_models.dart';

class MushafPage extends ConsumerWidget {
  final String thumnTitle;
  final List<Ayah> ayahs;

  const MushafPage({
    super.key,
    required this.thumnTitle,
    required this.ayahs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    // Calculate current Hizb and Rub from the first visible Ayah
    // In a real app, we'd use a ScrollController to track the first visible item
    // For now, we'll use the first ayah which is usually the start of the page/selection
    final firstAyah = ayahs.first;

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                // Header: Thumn Title
                Semantics(
                  header: true,
                  label: 'العنوان: $thumnTitle',
                  child: Text(
                    thumnTitle,
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: settings.backgroundColor.computeLuminance() > 0.5 
                          ? Colors.black87 : Colors.white70,
                    ),
                  ),
                ),
                Divider(
                  thickness: 1, 
                  color: (settings.backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white).withOpacity(0.1)
                ),
                const SizedBox(height: 20),
                
                // Body: Verses
                Expanded(
                  child: SingleChildScrollView(
                    child: Semantics(
                      label: 'نص القرآن الكريم',
                      child: RichText(
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                        text: TextSpan(
                          children: _buildVerses(settings),
                          style: GoogleFonts.amiri(
                            fontSize: settings.fontSize * 0.9,
                            height: 2.0,
                            color: settings.backgroundColor.computeLuminance() > 0.5 
                                ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Position Indicator (Premium Look)
          Positioned(
            bottom: 30,
            right: 20,
            child: Semantics(
              label: 'المكان الحالي: الحزب ${firstAyah.hizb}, الربع ${firstAyah.rub}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'الحزب ${firstAyah.hizb} - الربع ${firstAyah.rub}',
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildVerses(AppSettings settings) {
    List<TextSpan> spans = [];
    for (int i = 0; i < ayahs.length; i++) {
      final ayah = ayahs[i];
      spans.add(TextSpan(
        text: '${ayah.text} ',
        semanticsLabel: 'آية ${ayah.numberInSurah}',
      ));
      spans.add(
        TextSpan(
          text: ' ﴾${ayah.numberInSurah}﴿ ',
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: settings.fontSize * 0.6,
          ),
        ),
      );
    }
    return spans;
  }
}
