import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';
import '../../core/quran_provider.dart';
import '../../core/settings_provider.dart';
import '../../core/models/quran_models.dart';
import '../../core/app_theme.dart';

class MushafPage extends ConsumerStatefulWidget {
  final String thumnTitle;
  final List<Ayah> ayahs;

  const MushafPage({
    super.key,
    required this.thumnTitle,
    required this.ayahs,
  });

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  final ScrollController _scrollController = ScrollController();
  int _visibleAyahIndex = 0;
  final GlobalKey _targetAyahKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Auto-scroll when recitation proceeds
    ref.listenManual(currentPlayingAyahProvider, (previous, next) {
      if (next != null) {
        _scrollToAyah(next);
      }
    });
    
    // Check for target ayah and scroll to it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final targetAyah = ref.read(targetAyahGlobalNumberProvider);
      if (targetAyah != null) {
        final hasTarget = widget.ayahs.any((a) => a.number == targetAyah);
        if (hasTarget && _targetAyahKey.currentContext != null) {
          Scrollable.ensureVisible(
            _targetAyahKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          ref.read(targetAyahGlobalNumberProvider.notifier).state = null;
        }
      }
    });
  }

  void _scrollToAyah(Ayah ayah) {
    if (!mounted) return;
    final index = widget.ayahs.indexWhere((a) => a.number == ayah.number);
    if (index != -1) {
      // We need a way to find the context for this specific ayah.
      // Since they are inline in a RichText, we can't easily get a context per ayah.
      // HOWEVER, we can calculate the approximate scroll position based on index.
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetOffset = (maxScroll / widget.ayahs.length) * index;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.ayahs.isEmpty) return;
    
    double maxScroll = _scrollController.position.maxScrollExtent;
    double currentScroll = _scrollController.offset;
    
    if (maxScroll > 0) {
      // Ensure the calculation doesn't produce a negative index
      int ayahsCount = widget.ayahs.length;
      int newIndex = ((currentScroll / maxScroll) * (ayahsCount - 1)).round().clamp(0, ayahsCount - 1);
      
      if (newIndex != _visibleAyahIndex) {
        setState(() {
          _visibleAyahIndex = newIndex;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ayahs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final settings = ref.watch(settingsProvider);
    final currentAyah = widget.ayahs[_visibleAyahIndex.clamp(0, widget.ayahs.length - 1)];
    
    // Determine Thumun (1 or 2 of the current Rob3)
    int thumunInRob3 = _visibleAyahIndex < (widget.ayahs.length / 2) ? 1 : 2;
    int absoluteThumun = currentAyah.thumunBase + (thumunInRob3 - 1);

    return Material(
      color: settings.backgroundColor,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Header: Thumn Title with Premium Decoration
                Semantics(
                  header: true,
                  label: 'العنوان: ${widget.thumnTitle}',
                  child: Column(
                    children: [
                      Text(
                        widget.thumnTitle,
                        style: GoogleFonts.amiri(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emeraldGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.emeraldGreen.withOpacity(0),
                              AppTheme.richGold,
                              AppTheme.emeraldGreen.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Body: Verses with better spacing
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Semantics(
                      label: 'نص القرآن الكريم - ${widget.thumnTitle}',
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: RichText(
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            children: _buildVerses(settings),
                            style: GoogleFonts.amiri(
                              fontSize: settings.fontSize,
                              height: 2.2,
                              color: settings.backgroundColor.computeLuminance() > 0.5 
                                  ? const Color(0xFF1F2937) : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Position Indicator (Glassmorphism)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIndicatorTag('الحزب ${currentAyah.hizb}', Icons.auto_stories),
                      _buildIndicatorTag('الربع ${currentAyah.rub}', Icons.grid_view_rounded),
                      _buildIndicatorTag('الثمن $absoluteThumun', Icons.bookmark_added_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorTag(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.richGold, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.amiri(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  List<InlineSpan> _buildVerses(AppSettings settings) {
    List<InlineSpan> spans = [];
    int? lastSurah;
    final targetAyah = ref.read(targetAyahGlobalNumberProvider);

    // The Bismillah string often used in APIs
    const String apiBismillah = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

    for (int i = 0; i < widget.ayahs.length; i++) {
      final ayah = widget.ayahs[i];
      
      // Add the key if this is the target ayah to scroll to
      if (ayah.number == targetAyah) {
        spans.add(WidgetSpan(child: SizedBox.shrink(key: _targetAyahKey)));
      }

      // Surah Header if surah changes AND it's the first ayah of that surah
      if (lastSurah != ayah.surahNumber && ayah.numberInSurah == 1) {
        // Add header
        spans.add(TextSpan(
          text: '\n${ayah.surahName}\n',
          style: GoogleFonts.amiri(
            fontSize: settings.fontSize * 1.3,
            fontWeight: FontWeight.bold,
            color: AppTheme.richGold,
          ),
        ));

        // Add Bismillah (except At-Tawbah and Al-Fatihah)
        // Note: For Al-Fatihah (Surah 1), the first ayah IS the Bismillah in most Mushafs.
        // For others, it's a header.
        if (ayah.surahNumber != 9 && ayah.surahNumber != 1) {
          spans.add(TextSpan(
            text: '$apiBismillah\n',
            style: GoogleFonts.amiri(
              fontSize: settings.fontSize * 0.9,
              fontWeight: FontWeight.bold,
              color: settings.backgroundColor.computeLuminance() > 0.5 
                  ? Colors.black87 : Colors.white70,
            ),
          ));
        }
        lastSurah = ayah.surahNumber;
      } else if (lastSurah == null) {
        // Initialize lastSurah for continuation pages without header
        lastSurah = ayah.surahNumber;
      }
      
      // Process ayah text: remove embedded Bismillah if we are at the start of a Surah (except Fatihah)
      String displayedText = ayah.text;
      if (ayah.numberInSurah == 1 && ayah.surahNumber != 1) {
        // Remove Bismillah from the start of the text if it's there
        if (displayedText.startsWith(apiBismillah)) {
          displayedText = displayedText.replaceFirst(apiBismillah, '').trim();
        } else {
          // Fallback check without diacritics if needed, but typically the API is consistent
          final cleanBismillah = 'بِسمِ اللَّهِ الرَّحمٰنِ الرَّحيمِ';
          if (displayedText.startsWith(cleanBismillah)) {
            displayedText = displayedText.replaceFirst(cleanBismillah, '').trim();
          }
        }
      }

      spans.add(TextSpan(
        text: '$displayedText ',
        style: GoogleFonts.amiri(
          fontSize: settings.fontSize,
          height: 2.2,
          color: settings.backgroundColor.computeLuminance() > 0.5 
              ? (ref.watch(currentPlayingAyahProvider)?.number == ayah.number 
                  ? AppTheme.emeraldGreen : const Color(0xFF1F2937)) 
              : (ref.watch(currentPlayingAyahProvider)?.number == ayah.number 
                  ? AppTheme.richGold : Colors.white),
          fontWeight: ref.watch(currentPlayingAyahProvider)?.number == ayah.number 
              ? FontWeight.bold : FontWeight.normal,
        ),
        recognizer: TapGestureRecognizer()..onTap = () {
          HapticFeedback.lightImpact();
          ref.read(currentPlayingAyahProvider.notifier).playAyah(ayah);
        },
        semanticsLabel: 'آية ${ayah.numberInSurah}',
      ));

      // Add Ayah Number Badge
      spans.add(
        TextSpan(
          text: ' ﴿${ayah.numberInSurah}﴾ ',
          style: TextStyle(
            color: AppTheme.richGold,
            fontWeight: FontWeight.bold,
            fontSize: settings.fontSize * 0.7,
          ),
        ),
      );

      // Add Phonetics if enabled
      if (settings.showPhonetics && ayah.phonetics != null) {
        spans.add(TextSpan(
          text: '\n[ ${ayah.phonetics} ]\n',
          style: GoogleFonts.inter(
            fontSize: settings.fontSize * 0.5,
            color: AppTheme.richGold.withValues(alpha: 0.9),
            fontStyle: FontStyle.italic,
          ),
        ));
      }

      // Add Translation if enabled
      if (settings.showTranslation && ayah.translation != null) {
        final translations = ayah.translation!.split('|||');
        String translationText = '';
        if (settings.translationLanguage == 'Français' && translations.length > 0) {
          translationText = translations[0];
        } else if (settings.translationLanguage == 'English' && translations.length > 1) {
          translationText = translations[1];
        }

        if (translationText.isNotEmpty) {
          spans.add(TextSpan(
            text: '\n$translationText\n',
            style: GoogleFonts.outfit(
              fontSize: settings.fontSize * 0.55,
              color: settings.backgroundColor.computeLuminance() > 0.5 
                  ? Colors.black54 : Colors.white70,
              height: 1.5,
            ),
          ));
        }
      }
      
      // Add extra space if translation or phonetics added
      if (settings.showTranslation || settings.showPhonetics) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }
}
