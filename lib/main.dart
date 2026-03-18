import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_theme.dart';
import 'core/firebase_options.dart' as manual;
import 'features/splash_screen.dart';
import 'features/mushaf/mushaf_view.dart';
import 'features/ahzab/ahzab_view.dart';
import 'features/suwar/suwar_view.dart';
import 'features/home/quick_actions_view.dart';
import 'features/settings/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Correctly initialize Firebase with the custom FirebaseOptions class
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: manual.FirebaseOptions.currentPlatform.apiKey,
        appId: manual.FirebaseOptions.currentPlatform.appId,
        messagingSenderId: manual.FirebaseOptions.currentPlatform.messagingSenderId,
        projectId: manual.FirebaseOptions.currentPlatform.projectId,
        authDomain: manual.FirebaseOptions.currentPlatform.authDomain,
        storageBucket: manual.FirebaseOptions.currentPlatform.storageBucket,
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(
    const ProviderScope(
      child: LawhiApp(),
    ),
  );
}




class LawhiApp extends ConsumerWidget {
  const LawhiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lawhi',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Using Light mode for the colorful red/green look
      home: const SplashScreenEntry(),
    );
  }
}

class SplashScreenEntry extends StatefulWidget {
  const SplashScreenEntry({super.key});

  @override
  State<SplashScreenEntry> createState() => _SplashScreenEntryState();
}

class _SplashScreenEntryState extends State<SplashScreenEntry> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 1; // Start with Suwar (Middle)

  final List<Widget> _pages = const [
    AhzabView(),
    SuwarView(),
    QuickActionsView(),
  ];


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leadingWidth: 100,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 28, color: Colors.blue),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsView()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu_book_outlined, size: 28, color: Colors.blue),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MushafView()),
                );
              },
            ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.edit, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'رواية ورش',
              style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.black.withValues(alpha: 0.1)),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: AppTheme.brandRed,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCustomNavItem(0, Icons.format_list_bulleted, 'الأحزاب', '60'),
            _buildCustomNavItem(1, Icons.menu_book, 'السور', '114'),
            _buildCustomNavItem(2, Icons.search, 'البحث', ''),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavItem(int index, IconData icon, String label, String badge) {
    bool isSelected = _currentIndex == index;
    String semanticLabel = label;
    if (badge.isNotEmpty) {
      semanticLabel += ', $badge elements';
    }
    if (isSelected) {
      semanticLabel += ', Selected';
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 32, color: isSelected ? Colors.white : Colors.white70),
                if (badge.isNotEmpty)
                  Positioned(
                    top: -5,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              label,
              style: GoogleFonts.amiri(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MushafViewEntry extends StatelessWidget {
  const MushafViewEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const MushafView();
  }
}


