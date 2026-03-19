import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mushaf_page.dart';
import 'widgets/riwaya_selection_dialog.dart';
import '../settings/settings_view.dart';
import '../../core/quran_provider.dart';
import '../../core/widgets/siraaj_error_view.dart';
import '../../core/settings_provider.dart';
import '../../core/app_theme.dart';
import '../../core/models/quran_models.dart';

class MushafView extends ConsumerStatefulWidget {
  const MushafView({super.key});

  @override
  ConsumerState<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends ConsumerState<MushafView> {
  late PageController _pageController;
  int _currentThumun = 1;

  @override
  void initState() {
    super.initState();
    _currentThumun = ref.read(currentThumunIndexProvider);
    _pageController = PageController(initialPage: _currentThumun - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
                      style: GoogleFonts.amiri(
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
              style: GoogleFonts.amiri(
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
          
          // Update last read info dynamicly with Surah and Ayah
          final ayahs = await ref.read(thumunAyahsProvider(thumun).future);
          if (ayahs.isNotEmpty) {
            final firstAyah = ayahs.first;
            ref.read(lastReadProvider.notifier).state = '${firstAyah.surahName} • آية ${firstAyah.numberInSurah}';
            
            // Announcement for screen readers
            SemanticsService.announce(
              'أنت الآن في ${firstAyah.surahName}، آية ${firstAyah.numberInSurah}', 
              TextDirection.rtl
            );
          }
          HapticFeedback.selectionClick();
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
                    style: GoogleFonts.amiri(
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
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final playingAyah = ref.read(currentPlayingAyahProvider);
          
          if (playingAyah == null) {
            // Start playing the first ayah of the current view
            final currentThumun = ref.read(currentThumunIndexProvider);
            // We need the first ayah of this thumun. 
            // For simplicity, let's trigger it from the current Hizb/Quarter
            final ayahs = await ref.read(hizbQuarterAyahsProvider((currentThumun / 8).ceil()).future);
            if (ayahs.isNotEmpty) {
              ref.read(currentPlayingAyahProvider.notifier).playAyah(ayahs.first);
            }
          } else {
            ref.read(currentPlayingAyahProvider.notifier).togglePlayPause();
          }
        },
        backgroundColor: AppTheme.emeraldGreen,
        child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
