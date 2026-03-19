import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/quran_provider.dart';
import '../../core/app_theme.dart';
import '../mushaf/mushaf_view.dart';

class AhzabView extends ConsumerWidget {
  const AhzabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.emeraldGreen,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'فهرس الأحزاب',
                style: GoogleFonts.amiri(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppTheme.emeraldGreen,
                      AppTheme.emeraldGreen.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Opacity(
                  opacity: 0.1,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                    ),
                    itemBuilder: (context, index) => Icon(Icons.star, color: Colors.white.withValues(alpha: 0.3), size: 20),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: 60,
              itemBuilder: (context, index) {
                final hizbNumber = index + 1;
                return _HizbCard(hizbNumber: hizbNumber);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HizbCard extends ConsumerWidget {
  final int hizbNumber;

  const _HizbCard({required this.hizbNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstAyahAsync = ref.watch(hizbFirstAyahProvider(hizbNumber));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Semantics(
        label: 'الحزب $hizbNumber، اضغط للبدء من بداية الحزب',
        button: true,
        onTapHint: 'الذهاب إلى الحزب $hizbNumber',
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            final firstThumunOfHizb = (hizbNumber - 1) * 8 + 1;
            ref.read(currentThumunIndexProvider.notifier).state = firstThumunOfHizb;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MushafView(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.emeraldGreen, AppTheme.emeraldGreen.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emeraldGreen.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$hizbNumber',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: 'Lecture du Hizb $hizbNumber',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.richGold, size: 40),
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              final firstAyah = await firstAyahAsync.value;
                              if (firstAyah != null) {
                                ref.read(currentPlayingAyahProvider.notifier).playAyah(firstAyah);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'الحزب $hizbNumber',
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.05)),
                  ),
                  child: firstAyahAsync.when(
                    loading: () => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldGreen),
                      ),
                    ),
                    error: (err, stack) => Text(
                      'اضغط لعرض محتوى الحزب $hizbNumber كاملاً...',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        color: Colors.black26,
                      ),
                    ),
                    data: (ayah) => Text(
                      '${ayah.text}...',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        color: const Color(0xFF4B5563),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'عرض الحزب',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.emeraldGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.emeraldGreen),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
