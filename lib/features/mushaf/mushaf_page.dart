import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings_provider.dart';
import '../../core/models/quran_models.dart';
import '../../core/app_theme.dart';

import 'dart:ui';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Estimating the visible ayah index based on scroll position
    // In a more complex app, we'd use a ListView.builder with a listener
    // But since we use SingleChildScrollView + RichText, we'll use a proportional estimate
    if (!_scrollController.hasClients) return;
    
    double maxScroll = _scrollController.position.maxScrollExtent;
    double currentScroll = _scrollController.offset;
    
    if (maxScroll > 0) {
      int newIndex = ((currentScroll / maxScroll) * (widget.ayahs.length - 1)).round();
      if (newIndex != _visibleAyahIndex) {
        setState(() {
          _visibleAyahIndex = newIndex;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final currentAyah = widget.ayahs[_visibleAyahIndex];
    
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
                              AppTheme.emeraldGreen.withValues(alpha: 0),
                              AppTheme.richGold,
                              AppTheme.emeraldGreen.withValues(alpha: 0),
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

  List<TextSpan> _buildVerses(AppSettings settings) {
    List<TextSpan> spans = [];
    for (int i = 0; i < widget.ayahs.length; i++) {
      final ayah = widget.ayahs[i];
      spans.add(TextSpan(
        text: '${ayah.text} ',
        semanticsLabel: 'آية ${ayah.numberInSurah}',
      ));
      spans.add(
        TextSpan(
          text: ' ﴾${ayah.numberInSurah}﴿ ',
          style: TextStyle(
            color: AppTheme.richGold,
            fontWeight: FontWeight.bold,
            fontSize: settings.fontSize * 0.7,
          ),
        ),
      );
    }
    return spans;
  }
}
