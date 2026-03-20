import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList.builder(
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

class _HizbCard extends ConsumerStatefulWidget {
  final int hizbNumber;
  const _HizbCard({required this.hizbNumber});

  @override
  ConsumerState<_HizbCard> createState() => _HizbCardState();
}

class _HizbCardState extends ConsumerState<_HizbCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentAyah = ref.watch(currentPlayingAyahProvider);
    final bool isThisHizbActive = currentAyah != null && currentAyah.hizb == widget.hizbNumber;
    final bool isPlaying = ref.watch(isPlayingProvider).value ?? false;

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
        label: 'الحزب ${widget.hizbNumber}، اضغط للبدء من بداية الحزب',
        button: true,
        onTapHint: 'الذهاب إلى الحزب ${widget.hizbNumber}',
        child: InkWell(
          onTap: () async {
            if (_isLoading) return;
            HapticFeedback.lightImpact();
            
            setState(() => _isLoading = true);
            
            try {
              // Resolve the starting ayah of the hizb first for accurate navigation
              final firstAyah = await ref.read(hizbFirstAyahProvider(widget.hizbNumber).future);
              if (!mounted) return;
              
              ref.read(targetAyahGlobalNumberProvider.notifier).state = firstAyah.number;
              ref.read(selectedSurahNumberProvider.notifier).state = firstAyah.surahNumber;

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MushafView()),
                ).then((_) {
                  if (mounted) {
                    ref.read(selectedSurahNumberProvider.notifier).state = null;
                    ref.read(targetAyahGlobalNumberProvider.notifier).state = null;
                  }
                });
              }
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
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
                            child: _isLoading 
                             ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                             : Text(
                                '${widget.hizbNumber}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: (isThisHizbActive && isPlaying) ? 'Pause du Hizb ${widget.hizbNumber}' : 'Lecture du Hizb ${widget.hizbNumber}',
                          button: true,
                          child: IconButton(
                            icon: Icon(
                              (isThisHizbActive && isPlaying) ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, 
                              color: AppTheme.richGold, 
                              size: 40
                            ),
                            onPressed: () async {
                              if (_isLoading) return;
                              HapticFeedback.lightImpact();
                              
                              setState(() => _isLoading = true);
                              
                              try {
                                final firstAyah = await ref.read(hizbFirstAyahProvider(widget.hizbNumber).future);
                                if (!mounted) return;
                                
                                final firstThumunOfHizb = (widget.hizbNumber - 1) * 8 + 1;
                                ref.read(currentThumunIndexProvider.notifier).state = firstThumunOfHizb;
                                ref.read(targetAyahGlobalNumberProvider.notifier).state = firstAyah.number;
                                ref.read(selectedSurahNumberProvider.notifier).state = firstAyah.surahNumber;
                                
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MushafView()),
                                  ).then((_) {
                                    if (mounted) {
                                      ref.read(selectedSurahNumberProvider.notifier).state = null;
                                    }
                                  });
                                }

                                // Start audio properly synced
                                await ref.read(currentPlayingAyahProvider.notifier).playAyah(firstAyah);
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'الحزب ${widget.hizbNumber}',
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
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
                  child: ref.watch(hizbFirstAyahProvider(widget.hizbNumber)).when(
                    loading: () => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldGreen),
                      ),
                    ),
                    error: (err, stack) => Text(
                      'اضغط لعرض محتوى الحزب ${widget.hizbNumber} كاملاً...',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, color: Colors.grey),
                    ),
                    data: (ayah) => Text(
                      '${ayah.text}...',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 18, color: Color(0xFF4B5563), height: 1.6),
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
                            style: const TextStyle(
                              fontFamily: 'Inter',
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
