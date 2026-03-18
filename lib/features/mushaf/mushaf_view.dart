import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mushaf_page.dart';
import '../settings/settings_view.dart';
import '../../core/quran_provider.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate Hizb and Rub for display
    final currentHizb = ((_currentThumun - 1) / 8).floor() + 1;
    final currentRubInHizb = (((_currentThumun - 1) % 8) / 2).floor() + 1;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'المصحف - لوح مروكي',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onSurface),
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
        onPageChanged: (index) {
          setState(() {
            _currentThumun = index + 1;
          });
          ref.read(currentThumunIndexProvider.notifier).state = _currentThumun;
        },
        itemBuilder: (context, index) {
          final thumunIdx = index + 1;
          final thumunAyahsAsync = ref.watch(thumunAyahsProvider(thumunIdx));
          
          return thumunAyahsAsync.when(
            data: (ayahs) => MushafPage(
              thumnTitle: 'الحزب $currentHizb - الربع $currentRubInHizb',
              ayahs: ayahs,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: colorScheme.surfaceContainer,
        elevation: 8,
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, 
                color: _currentThumun > 1 ? colorScheme.primary : Colors.grey),
              onPressed: () {
                if (_currentThumun > 1) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الحزب $currentHizb',
                  style: GoogleFonts.amiri(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'الثمن ${_currentThumun % 8 == 0 ? 8 : _currentThumun % 8}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, 
                color: _currentThumun < 480 ? colorScheme.primary : Colors.grey),
              onPressed: () {
                if (_currentThumun < 480) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
