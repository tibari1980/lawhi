import 'package:flutter/material.dart';
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
  final int thumunIndex;

  const MushafPage({
    super.key,
    required this.thumnTitle,
    required this.ayahs,
    required this.thumunIndex,
  });

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _visibleAyahIndexNotifier = ValueNotifier<int>(0);
  final GlobalKey _targetAyahKey = GlobalKey();
  final GlobalKey _playingAyahKey = GlobalKey();
  dynamic _audioSyncSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Auto-scroll when recitation proceeds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audioSyncSubscription = ref.listenManual(currentPlayingAyahProvider, (previous, next) {
        if (next != null) {
          _scrollToAyah(next);
        }
      });
    });
    
    // Check for target ayah and scroll to it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final targetAyah = ref.read(targetAyahGlobalNumberProvider);
      if (targetAyah != null) {
        final hasTarget = widget.ayahs.any((a) => a.number == targetAyah);
        if (hasTarget) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _targetAyahKey.currentContext != null) {
              Scrollable.ensureVisible(
                _targetAyahKey.currentContext!,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
              ref.read(targetAyahGlobalNumberProvider.notifier).state = null;
            }
          });
        }
      }
    });
  }

  void _scrollToAyah(Ayah ayah) {
    if (!mounted) return;
    final hasAyah = widget.ayahs.any((a) => a.number == ayah.number);
    if (hasAyah) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _playingAyahKey.currentContext != null) {
          Scrollable.ensureVisible(
            _playingAyahKey.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.2, // Keep it towards the top for better reading
          );
        } else if (mounted && _scrollController.hasClients) {
          final index = widget.ayahs.indexWhere((a) => a.number == ayah.number);
          final maxScroll = _scrollController.position.maxScrollExtent;
          final targetOffset = (maxScroll / widget.ayahs.length) * index;
          _scrollController.animateTo(
            targetOffset.clamp(0.0, maxScroll),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _visibleAyahIndexNotifier.dispose();
    _audioSyncSubscription?.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.ayahs.isEmpty) return;
    
    double maxScroll = _scrollController.position.maxScrollExtent;
    double currentScroll = _scrollController.offset;
    
    if (maxScroll > 0) {
      int ayahsCount = widget.ayahs.length;
      int newIndex = ((currentScroll / maxScroll) * (ayahsCount - 1)).round().clamp(0, ayahsCount - 1);
      
      if (newIndex != _visibleAyahIndexNotifier.value) {
        _visibleAyahIndexNotifier.value = newIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ayahs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
    }
    
    final settings = ref.watch(settingsProvider);

    return Material(
      color: settings.backgroundColor,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Header
                Column(
                  children: [
                    Text(
                      widget.thumnTitle,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
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
                const SizedBox(height: 30),
                
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 150),
                      child: Column(
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              // We watch currentPlayingAyah here to highlight the active verse
                              final playingAyah = ref.watch(currentPlayingAyahProvider)?.number;
                              return RichText(
                                textAlign: TextAlign.justify,
                                textDirection: TextDirection.rtl,
                                text: TextSpan(
                                  children: _buildVerses(settings, playingAyah),
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: settings.fontSize,
                                    height: 2.2,
                                    color: settings.backgroundColor.computeLuminance() > 0.5 
                                        ? const Color(0xFF1F2937) : Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildEndSeparator(widget.thumunIndex),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Position Indicator (Glassmorphism) - Uses ValueListenableBuilder for performance
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ValueListenableBuilder<int>(
              valueListenable: _visibleAyahIndexNotifier,
              builder: (context, index, child) {
                final currentAyah = widget.ayahs[index.clamp(0, widget.ayahs.length - 1)];
                int thumunInRob3 = index < (widget.ayahs.length / 2) ? 1 : 2;
                int absoluteThumun = currentAyah.globalThumun + (thumunInRob3 - 1);

                return ClipRRect(
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
                          _buildIndicatorTag('الجزء ${currentAyah.juz}', Icons.auto_stories),
                          _buildIndicatorTag('الحزب ${currentAyah.hizb}', Icons.menu_book_rounded),
                          _buildIndicatorTag('الربع ${currentAyah.hizbQuarter}', Icons.grid_view_rounded),
                          _buildIndicatorTag('الثمن $absoluteThumun', Icons.bookmark_added_rounded),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndSeparator(int thumunIdx) {
    String label = "نهاية الثمن";
    if (thumunIdx % 8 == 0) {
      label = "نهاية الحزب ${thumunIdx ~/ 8}";
    } else if (thumunIdx % 2 == 0) {
      label = "نهاية الربع";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            height: 1.5,
            width: double.infinity,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.richGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppTheme.richGold, size: 14),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.richGold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded, color: AppTheme.richGold, size: 14),
              ],
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
          style: const TextStyle(fontFamily: 'Amiri', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  List<InlineSpan> _buildVerses(AppSettings settings, int? playingAyahNumber) {
    List<InlineSpan> spans = [];
    int? lastSurah;
    final targetAyah = ref.read(targetAyahGlobalNumberProvider);
    const String apiBismillah = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

    for (int i = 0; i < widget.ayahs.length; i++) {
      final ayah = widget.ayahs[i];
      final isPlaying = ayah.number == playingAyahNumber;
      
      if (ayah.number == targetAyah) {
        spans.add(WidgetSpan(child: SizedBox.shrink(key: _targetAyahKey)));
      }
      if (isPlaying) {
        spans.add(WidgetSpan(child: SizedBox.shrink(key: _playingAyahKey)));
      }

      if (lastSurah != ayah.surahNumber && ayah.numberInSurah == 1) {
        spans.add(TextSpan(
          text: '\n${ayah.surahName}\n',
          style: TextStyle(fontFamily: 'Amiri', fontSize: settings.fontSize * 1.3, fontWeight: FontWeight.bold, color: AppTheme.richGold),
        ));

        if (ayah.surahNumber != 9 && ayah.surahNumber != 1) {
          spans.add(TextSpan(
            text: '$apiBismillah\n',
            style: TextStyle(fontFamily: 'Amiri', fontSize: settings.fontSize * 0.9, fontWeight: FontWeight.bold, color: settings.backgroundColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white70),
          ));
        }
        lastSurah = ayah.surahNumber;
      }
      lastSurah ??= ayah.surahNumber;
      
      String displayedText = ayah.text;
      if (ayah.numberInSurah == 1 && ayah.surahNumber != 1) {
        if (displayedText.startsWith(apiBismillah)) {
          displayedText = displayedText.replaceFirst(apiBismillah, '').trim();
        }
      }

      spans.add(TextSpan(
        text: '$displayedText ',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: settings.fontSize,
          height: 2.2,
          color: isPlaying 
              ? (settings.backgroundColor.computeLuminance() > 0.5 ? AppTheme.emeraldGreen : AppTheme.richGold)
              : (settings.backgroundColor.computeLuminance() > 0.5 ? const Color(0xFF1F2937) : Colors.white),
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        ),
        recognizer: TapGestureRecognizer()..onTap = () {
          HapticFeedback.lightImpact();
          ref.read(currentPlayingAyahProvider.notifier).playAyah(ayah);
        },
      ));

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

      if (settings.showPhonetics && ayah.phonetics != null) {
        spans.add(TextSpan(
          text: '\n[ ${ayah.phonetics} ]\n',
          style: TextStyle(fontFamily: 'Inter', fontSize: settings.fontSize * 0.5, color: AppTheme.richGold.withValues(alpha: 0.9), fontStyle: FontStyle.italic),
        ));
      }

      if (settings.showTranslation && ayah.translation != null) {
        final translations = ayah.translation!.split('|||');
        String translationText = '';
        if (settings.translationLanguage == 'Français' && translations.isNotEmpty) {
          translationText = translations[0];
        } else if (settings.translationLanguage == 'English' && translations.length > 1) {
          translationText = translations[1];
        }

        if (translationText.isNotEmpty) {
          spans.add(TextSpan(
            text: '\n$translationText\n',
            style: TextStyle(fontFamily: 'Inter', fontSize: settings.fontSize * 0.55, color: settings.backgroundColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70, height: 1.5),
          ));
        }
      }
      
      if (settings.showTranslation || settings.showPhonetics) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }
}
