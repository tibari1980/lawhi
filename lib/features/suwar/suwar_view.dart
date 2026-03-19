import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/quran_provider.dart';
import '../../core/models/quran_models.dart';
import '../../core/widgets/siraaj_error_view.dart';
import '../mushaf/mushaf_view.dart';

class SuwarView extends ConsumerWidget {
  const SuwarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsyncValue = ref.watch(surahsProvider);

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
                'فهرس السور',
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
            child: surahsAsyncValue.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
              ),
              error: (err, stack) => SiraajErrorView(
                error: err.toString(),
                onRetry: () => ref.refresh(surahsProvider),
                isOffline: err.toString().contains('SocketException') || err.toString().contains('Connection'),
              ),
              data: (surahs) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return _SurahCard(surah: surah);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahCard extends ConsumerStatefulWidget {
  final Surah surah;
  const _SurahCard({required this.surah});

  @override
  ConsumerState<_SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends ConsumerState<_SurahCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
        label: 'سورة ${widget.surah.name}، ${widget.surah.numberOfAyahs} آية، ${widget.surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}',
        button: true,
        onTapHint: 'الذهاب إلى سورة ${widget.surah.name}',
        child: InkWell(
          onTap: _isLoading ? null : () async {
            setState(() => _isLoading = true);
            HapticFeedback.lightImpact();
            try {
              final ayahs = await ref.read(surahAyahsProvider(widget.surah.number).future);
              if (ayahs.isNotEmpty) {
                final firstAyah = ayahs.first;
                final quarterAyahs = await ref.read(hizbQuarterAyahsProvider(firstAyah.hizbQuarter).future);
                final startThumun = firstAyah.getThumunIndex(quarterAyahs);
                
                ref.read(currentThumunIndexProvider.notifier).state = startThumun;
                ref.read(targetAyahGlobalNumberProvider.notifier).state = firstAyah.number;
                ref.read(selectedSurahNumberProvider.notifier).state = widget.surah.number;
                
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MushafView()),
                  ).then((_) {
                    // Reset selection after returning
                    ref.read(selectedSurahNumberProvider.notifier).state = null;
                  });
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ في التحميل: ${e.toString()}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Number label with specific design
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldGreen))
                      : ExcludeSemantics(
                          child: Text(
                            '${widget.surah.number}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.emeraldGreen,
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.surah.englishName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '${widget.surah.numberOfAyahs} آية • ${widget.surah.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arabic name with calligraphy feel
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Hero(
                      tag: 'surah-name-${widget.surah.number}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          widget.surah.name,
                          style: GoogleFonts.amiri(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      widget.surah.revelationType == 'Meccan' ? Icons.mosque_rounded : Icons.temple_hindu_rounded, // Best available icons
                      size: 16,
                      color: AppTheme.richGold.withValues(alpha: 0.7),
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
