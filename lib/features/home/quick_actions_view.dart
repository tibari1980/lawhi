import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/quran_provider.dart';
import '../../core/models/user_progress.dart';
import '../../core/user_progress_provider.dart';
import 'dart:ui';
import '../mushaf/mushaf_view.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class QuickActionsView extends ConsumerWidget {
  const QuickActionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ref.watch(searchQueryProvider);
    final surahsAsync = ref.watch(surahsProvider);
    final lastRead = ref.watch(lastReadProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.emeraldGreen.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Glassmorphic Search Bar
              Semantics(
                label: 'Recherche de sourate par nom',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.richGold.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن سورة...',
                          hintStyle: GoogleFonts.amiri(color: Colors.grey[600], fontSize: 18),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.richGold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (query.isNotEmpty) ...[
                _buildSectionHeader('نتائج البحث'),
                const SizedBox(height: 16),
                surahsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
                  error: (e, s) => Center(child: Text('Error: $e')),
                  data: (surahs) {
                    final normalizedQuery = _normalizeArabic(query.toLowerCase());
                    final filtered = surahs.where((s) {
                      final normalizedName = _normalizeArabic(s.name);
                      final normalizedEnglish = s.englishName.toLowerCase();
                      return normalizedName.contains(normalizedQuery) || 
                             normalizedEnglish.contains(normalizedQuery);
                    }).toList();
                    
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 60),
                            Icon(Icons.search_off_rounded, size: 80, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text('لا توجد نتائج', style: GoogleFonts.amiri(fontSize: 22, color: theme.colorScheme.outline)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final surah = filtered[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.05)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emeraldGreen.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            onTap: () async {
                              final ayahsAsync = await ref.read(surahAyahsProvider(surah.number).future);
                              if (ayahsAsync.isNotEmpty) {
                                final firstAyah = ayahsAsync.first;
                                
                                // Start audio playback directly
                                ref.read(currentPlayingAyahProvider.notifier).playAyah(firstAyah);
                                
                                // Precision navigation
                                final quarterAyahs = await ref.read(hizbQuarterAyahsProvider(firstAyah.hizbQuarter).future);
                                final startThumun = firstAyah.getThumunIndex(quarterAyahs);
                                
                                ref.read(currentThumunIndexProvider.notifier).state = startThumun;
                                ref.read(targetAyahGlobalNumberProvider.notifier).state = firstAyah.number;
                                ref.read(lastReadProvider.notifier).state = 'سورة ${surah.name}';
                                if (context.mounted) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MushafView()));
                                }
                              }
                            },
                            leading: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.emeraldGreen, Color(0xFF065F46)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  surah.number.toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            title: Text(
                              surah.name, 
                              textAlign: TextAlign.right, 
                              style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            subtitle: Text(
                              surah.englishName, 
                              textAlign: TextAlign.right, 
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.richGold),
                          ),
                        );
                      },
                    );
                  },
                ),
              ] else ...[
                _buildSectionHeader('الوصول السريع'),
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, child) {
                    final progress = ref.watch(userProgressProvider);
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.95,
                      children: [
                        _buildPremiumActionCard(
                          context,
                          'سورة الكهف',
                          'بسرعة ودون بحث',
                          Icons.auto_stories_rounded,
                          const [Color(0xFFEF4444), Color(0xFFB91C1C)],
                          () async {
                            HapticFeedback.lightImpact();
                            final ayahsAsync = await ref.read(surahAyahsProvider(18).future);
                            if (ayahsAsync.isNotEmpty) {
                              final firstAyah = ayahsAsync.first;
                              
                              // Start playback
                              ref.read(currentPlayingAyahProvider.notifier).playAyah(firstAyah);
                              
                              // Precision navigation
                              final quarterAyahs = await ref.read(hizbQuarterAyahsProvider(firstAyah.hizbQuarter).future);
                              final startThumun = firstAyah.getThumunIndex(quarterAyahs);
                              
                              ref.read(currentThumunIndexProvider.notifier).state = startThumun;
                              ref.read(targetAyahGlobalNumberProvider.notifier).state = firstAyah.number;
                              ref.read(lastReadProvider.notifier).state = 'سورة الكهف';
                              if (context.mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const MushafView()));
                              }
                            }
                          },
                          semanticLabel: 'قراءة سورة الكهف، اختصار سريع لسورة الكهف',
                        ),
                        _buildPremiumActionCard(
                          context,
                          'موقع التلاوة',
                          lastRead,
                          Icons.chrome_reader_mode_rounded,
                          const [AppTheme.emeraldGreen, Color(0xFF065F46)],
                          () {
                            HapticFeedback.lightImpact();
                            final playingAyah = ref.read(currentPlayingAyahProvider);
                            if (playingAyah != null) {
                              ref.read(currentPlayingAyahProvider.notifier).togglePlayPause();
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const MushafView()));
                          },
                          semanticLabel: 'موقع التلاوة، استكمال القراءة من: $lastRead',
                        ),
                        _buildPremiumActionCard(
                          context,
                          'موقع الحفظ',
                          'أتممت ${progress.hifzCount} ثمن',
                          Icons.task_alt_rounded,
                          const [AppTheme.richGold, Color(0xFFB45309)],
                          () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => _buildHifzBottomSheet(context, ref, progress),
                            );
                          },
                          semanticLabel: 'موقع الحفظ، تقدمك الحالي هو ${progress.hifzCount} أثمان',
                        ),
                        _buildPremiumActionCard(
                          context,
                          'موقع المراجعة',
                          'لديك ${progress.revisionList.length} أجزاء للمراجعة',
                          Icons.history_rounded,
                          const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => _buildRevisionBottomSheet(context, ref, progress),
                            );
                          },
                          semanticLabel: 'موقع المراجعة، لديك ${progress.revisionList.length} أجزاء للمراجعة اليوم',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHifzBottomSheet(BuildContext context, WidgetRef ref, UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('تقدم الحفظ', style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('لقد أتممت حفظ ${progress.hifzCount} ثمن من القرآن الكريم', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700])),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.read(currentThumunIndexProvider.notifier).state = progress.lastHifzThumun;
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MushafView()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.richGold,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('متابعة الحفظ', style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.read(userProgressProvider.notifier).addHifzProgress();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث التقدم بنجاح!', textAlign: TextAlign.right)));
            },
            child: Text('تحديد الثمن الحالي كمكتمل', style: GoogleFonts.amiri(fontSize: 18, color: AppTheme.richGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionBottomSheet(BuildContext context, WidgetRef ref, UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('قائمة المراجعة اليومية', style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (progress.revisionList.isEmpty)
            Text('لا توجد أجزاء للمراجعة حالياً', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]))
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: progress.revisionList.length,
              itemBuilder: (context, index) {
                final hizb = progress.revisionList[index];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.menu_book_rounded, color: Color(0xFF3B82F6))),
                  title: Text('الحزب $hizb', style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    final startThumun = (hizb - 1) * 8 + 1;
                    ref.read(currentThumunIndexProvider.notifier).state = startThumun;
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MushafView()));
                  },
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.amiri(
            fontSize: 28, 
            fontWeight: FontWeight.bold, 
            color: AppTheme.emeraldGreen,
          ),
        ),
        Container(
          width: 60,
          height: 4,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.richGold, Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') // Remove diacritics
        .replaceAll(RegExp(r'[أإآ]'), 'ا')           // Normalize Alef
        .replaceAll('ة', 'ه')                        // Normalize Teh Marbuta
        .replaceAll('ى', 'ي');                       // Normalize Yeh
  }

   Widget _buildPremiumActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap, {
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel ?? title,
      button: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative background icon
              Positioned(
                right: -20,
                bottom: -20,
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: 100,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                  crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 48, // Enlarged icon
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 22, // Slightly larger
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
