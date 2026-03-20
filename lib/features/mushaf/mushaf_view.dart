import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mushaf_page.dart';
import 'widgets/riwaya_selection_dialog.dart';
import '../settings/settings_view.dart';
import '../../core/quran_provider.dart';
import '../../core/widgets/siraaj_error_view.dart';
import '../../core/settings_provider.dart';
import '../../core/app_theme.dart';
import '../../core/models/quran_models.dart';
import '../../core/user_progress_provider.dart';

class MushafView extends ConsumerStatefulWidget {
  const MushafView({super.key});

  @override
  ConsumerState<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends ConsumerState<MushafView> {
  late PageController _pageController;
  int _currentThumun = 1;
  dynamic _audioSyncSubscription;

  @override
  void initState() {
    super.initState();
    
    // Determine initial page
    _currentThumun = ref.read(currentThumunIndexProvider);
    _pageController = PageController(initialPage: _currentThumun - 1);

    // Listen for manual navigation targets (from SuwarView/Search)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listenManual(targetAyahGlobalNumberProvider, (previous, next) async {
        if (next != null) {
          final ayah = await ref.read(quranServiceProvider).getAyahByGlobalNumber(next);
          if (!mounted) return;
          if (ayah != null) {
            final quarterAyahs = await ref.read(hizbQuarterAyahsProvider(ayah.hizbQuarter).future);
            if (!mounted) return;
            final thumunIndex = ayah.getThumunIndex(quarterAyahs);
            
            if (thumunIndex != _currentThumun) {
              _currentThumun = thumunIndex;
              _pageController.jumpToPage(thumunIndex - 1);
            }
          }
        }
      }, fireImmediately: true);
    });

    // Continuous sync with audio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audioSyncSubscription = ref.listenManual(currentPlayingAyahProvider, (previous, next) async {
        if (next != null) {
          // Find the thumun of this ayah
          final quarterAyahs = await ref.read(hizbQuarterAyahsProvider(next.hizbQuarter).future);
          if (!mounted) return;
          final thumunIndex = next.getThumunIndex(quarterAyahs);
          
          if (thumunIndex != _currentThumun) {
            _currentThumun = thumunIndex;
            _pageController.animateToPage(
              thumunIndex - 1,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioSyncSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final selectedSurahNum = ref.watch(selectedSurahNumberProvider);
    final isLight = settings.backgroundColor.computeLuminance() > 0.5;
    final contentColor = isLight ? const Color(0xFF1F2937) : Colors.white;
    
    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.backgroundColor,
        centerTitle: true,
        title: selectedSurahNum != null 
          ? Hero(
              tag: 'surah-name-$selectedSurahNum',
              child: Material(
                color: Colors.transparent,
                child: FutureBuilder<List<Surah>>(
                  future: ref.read(surahsProvider.future),
                  builder: (context, snapshot) {
                    final surah = snapshot.data?.firstWhere((s) => s.number == selectedSurahNum);
                    final name = surah?.name ?? 'القرآن الكريم';
                    return Text(
                      name,
                      style: const TextStyle(fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        color: AppTheme.emeraldGreen,
                        fontSize: 22,
                      ),
                    );
                  }
                ),
              ),
            )
          : Text(
              'القرآن السراج',
              style: TextStyle(fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                color: contentColor,
              ),
            ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: contentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Tooltip(
              message: 'تغيير الرواية',
              child: Icon(Icons.menu_book, color: AppTheme.emeraldGreen),
            ),
            onPressed: () => showRiwayaSelectionDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: contentColor),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsView()),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: 480,
        onPageChanged: (index) async {
          final thumun = index + 1;
          setState(() {
            _currentThumun = thumun;
          });
          ref.read(currentThumunIndexProvider.notifier).state = thumun;
          
          // Update persistent progress (local Firestore cache + Online sync)
          ref.read(userProgressProvider.notifier).updateLastRead(thumun);
          
          // Update last read info dynamicly with Surah and Ayah
          try {
            final ayahs = await ref.read(thumunAyahsProvider(thumun).future);
            if (!mounted) return;
            
            if (ayahs.isNotEmpty) {
              final firstAyah = ayahs.first;
              ref.read(lastReadProvider.notifier).state = '${firstAyah.surahName} • آية ${firstAyah.numberInSurah}';
              
              if (context.mounted) {
                // Announcement for screen readers
                SemanticsService.sendAnnouncement(
                  View.of(context),
                  'أنت الآن في ${firstAyah.surahName}، آية ${firstAyah.numberInSurah}', 
                  TextDirection.rtl
                );
              }
            }
          } catch (e) {
            debugPrint('Error updating progress: $e');
          }
          if (mounted) HapticFeedback.selectionClick();
        },
        itemBuilder: (context, index) {
          final thumunIdx = index + 1;
          final thumunAyahsAsync = ref.watch(thumunAyahsProvider(thumunIdx));

          return thumunAyahsAsync.when(
            data: (ayahs) {
              final hizb = ((thumunIdx - 1) / 8).floor() + 1;
              final rub = (((thumunIdx - 1) % 8) / 2).floor() + 1;
              return MushafPage(
                thumnTitle: 'الحزب $hizb - الربع $rub',
                ayahs: ayahs,
                thumunIndex: thumunIdx,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen)),
            error: (err, stack) => SiraajErrorView(
              error: err.toString(),
              onRetry: () => ref.refresh(thumunAyahsProvider(thumunIdx)),
              isOffline: err.toString().contains('SocketException') || err.toString().contains('Connection'),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: 'الثمن السابق',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
            Consumer(
              builder: (context, ref, child) {
                final hizb = ((_currentThumun - 1) / 8).floor() + 1;
                final rub = (((_currentThumun - 1) % 8) / 2).floor() + 1;
                return Semantics(
                  label: 'الحزب $hizb الربع $rub',
                  child: Text(
                    'الحزب $hizb • الربع $rub',
                    style: const TextStyle(fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.emeraldGreen,
                    ),
                  ),
                );
              },
            ),
            Semantics(
              label: 'الثمن التالي',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          final playingAyah = ref.read(currentPlayingAyahProvider);
          
          if (playingAyah == null) {
            // Start playing the first ayah of the current view
            final currentThumun = ref.read(currentThumunIndexProvider);
            ref.read(thumunAyahsProvider(currentThumun).future).then((ayahs) {
              if (ayahs.isNotEmpty) {
                ref.read(currentPlayingAyahProvider.notifier).playAyah(ayahs.first);
              }
            });
          } else {
            ref.read(currentPlayingAyahProvider.notifier).togglePlayPause();
          }
        },
        backgroundColor: AppTheme.emeraldGreen,
        child: Icon(
          ref.watch(optimisticIsPlayingProvider) ? Icons.pause_rounded : Icons.play_arrow_rounded, 
          size: 36, 
          color: Colors.white
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
