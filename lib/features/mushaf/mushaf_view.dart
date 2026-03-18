import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mushaf_page.dart';
import '../settings/settings_view.dart';
import '../../core/quran_provider.dart';
import '../../core/models/quran_models.dart';

class MushafView extends ConsumerStatefulWidget {
  const MushafView({super.key});

  @override
  ConsumerState<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends ConsumerState<MushafView> {
  final PageController _pageController = PageController();
  int _currentHizb = 1;
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hizbAyahsAsync = ref.watch(hizbAyahsProvider(_currentHizb));

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
      body: hizbAyahsAsync.when(
        data: (ayahs) {
          // Group ayahs by Hizb Quarter (Rub)
          final Map<int, List<Ayah>> quarters = {};
          for (var ayah in ayahs) {
            quarters.putIfAbsent(ayah.hizbQuarter, () => []).add(ayah);
          }
          final quarterList = quarters.values.toList();

          return PageView.builder(
            controller: _pageController,
            itemCount: quarterList.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final quarterAyahs = quarterList[index];
              final firstAyah = quarterAyahs.first;
              return MushafPage(
                thumnTitle: 'الحزب ${_currentHizb} - الربع ${firstAyah.rub}',
                ayahs: quarterAyahs,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
                color: _currentIndex > 0 || _currentHizb > 1 ? colorScheme.primary : Colors.grey),
              onPressed: () {
                if (_currentIndex > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else if (_currentHizb > 1) {
                  setState(() {
                    _currentHizb--;
                    _currentIndex = 3; // Go to last quarter of previous hizb
                  });
                }
              },
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الحزب $_currentHizb',
                  style: GoogleFonts.amiri(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'الربع ${_currentIndex + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, 
                color: _currentHizb < 60 ? colorScheme.primary : Colors.grey),
              onPressed: () {
                // Determine if we have next quarter in current hizb
                final hizbData = ref.read(hizbAyahsProvider(_currentHizb)).asData;
                if (hizbData != null) {
                  final Map<int, List<Ayah>> quarters = {};
                  for (var ayah in hizbData.value) {
                    quarters.putIfAbsent(ayah.hizbQuarter, () => []).add(ayah);
                  }
                  if (_currentIndex < quarters.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else if (_currentHizb < 60) {
                    setState(() {
                      _currentHizb++;
                      _currentIndex = 0;
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
