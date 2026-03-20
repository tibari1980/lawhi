import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/quran_provider.dart';
import '../../core/navigation_provider.dart';
import '../../core/user_progress_provider.dart';
import '../mushaf/mushaf_view.dart';
import '../doua/doua_page.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadProvider);
    final progress = ref.watch(userProgressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Animated Header
          SliverToBoxAdapter(
            child: _buildHeader(context, ref),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          // Verse of the Day (Prominent Card)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildVerseOfTheDay(context, ref),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Progress & Last Read Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: _buildProgressCard(context, progress.hifzCount)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildLastReadMiniCard(context, lastRead)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Navigation Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'استكشاف',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildNavCard(
                        context,
                        'فهرس السور',
                        '١١٤ سورة',
                        Icons.menu_book_rounded,
                        const Color(0xFF10B981),
                        () => ref.read(navigationProvider.notifier).state = 1,
                      ),
                      _buildNavCard(
                        context,
                        'الأحزاب',
                        '٦٠ حزب',
                        Icons.layers_rounded,
                        const Color(0xFF6366F1),
                        () => ref.read(navigationProvider.notifier).state = 2,
                      ),
                      _buildNavCard(
                        context,
                        'أذكار الصباح',
                        'بركة اليوم',
                        Icons.wb_sunny_rounded,
                        AppTheme.premiumGold,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DouaPage(type: ThikrType.sabah))),
                      ),
                      _buildNavCard(
                        context,
                        'أذكار المساء',
                        'طُمأنينة الليل',
                        Icons.dark_mode_rounded,
                        const Color(0xFF312E81),
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DouaPage(type: ThikrType.masaa))),
                      ),
                      _buildNavCard(
                        context,
                        'دعاء الختم',
                        'أذكار مأثورة',
                        Icons.auto_awesome_rounded,
                        const Color(0xFF8B5CF6),
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DouaPage(type: ThikrType.khatm))),
                      ),
                      _buildNavCard(
                        context,
                        'البحث',
                        'آيات ومواضيع',
                        Icons.search_rounded,
                        AppTheme.premiumGold,
                        () => ref.read(navigationProvider.notifier).state = 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    String greeting = "السلام عليكم";
    if (hour < 12) {
      greeting = "صباح الخير";
    } else if (hour < 18) {
      greeting = "أهلاً بك";
    } else {
      greeting = "مساء الخير";
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.emeraldGreen, Color(0xFF064E3B)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFDE68A), Color(0xFFD97706), Color(0xFFFDE68A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'القرآن السراج',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white,
                        fontSize: 34, // Slightly larger
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerseOfTheDay(BuildContext context, WidgetRef ref) {
    final featuredAyahAsync = ref.watch(featuredAyahProvider);
    return featuredAyahAsync.when(
      data: (ayah) {
        final isPlayingOptimistic = ref.watch(optimisticIsPlayingProvider);
        final currentAyah = ref.watch(currentPlayingAyahProvider);
        final bool isThisVersePlaying = currentAyah?.number == ayah.number && isPlayingOptimistic;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.emeraldGreen.withValues(alpha: 0.9), AppTheme.emeraldGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.emeraldGreen.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'آية اليوم',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Icon(Icons.star_rounded, color: Colors.white70, size: 20),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                ayah.text,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModernActionBtn(
                    isThisVersePlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                    isThisVersePlaying ? 'إيقاف' : 'استماع', 
                    () {
                      HapticFeedback.mediumImpact();
                      if (currentAyah?.number == ayah.number) {
                        ref.read(currentPlayingAyahProvider.notifier).togglePlayPause();
                      } else {
                        ref.read(currentPlayingAyahProvider.notifier).playAyah(ayah);
                      }
                    }
                  ),
                  const SizedBox(width: 16),
                  _buildModernActionBtn(
                    Icons.auto_stories_rounded, 
                    'قراءة', 
                    () async {
                      // Immediate navigation
                      final startThumun = (ayah.hizbQuarter - 1) * 2 + 1;
                      ref.read(currentThumunIndexProvider.notifier).state = startThumun;
                      ref.read(targetAyahGlobalNumberProvider.notifier).state = ayah.number;
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MushafView()));
                    }
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.premiumGold)),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.richGold.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.premiumGold, size: 40),
            const SizedBox(height: 12),
            Text(
              'اذهب للمصحف للمتابعة',
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.analytics_rounded, color: AppTheme.emeraldGreen),
          const SizedBox(height: 12),
          Text(
            'حفظك',
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, color: Colors.grey),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
              ),
              const SizedBox(width: 4),
              Text(
                'ثمن',
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastReadMiniCard(BuildContext context, String lastRead) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MushafView())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bookmark_rounded, color: AppTheme.premiumGold),
            const SizedBox(height: 12),
            Text(
              'آخر قراءة',
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, color: Colors.grey),
            ),
            Text(
              lastRead.split(' • ').first, // Just surah name for mini card
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Amiri', 
                fontSize: 19, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1F2937),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter', 
                fontSize: 12, 
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
