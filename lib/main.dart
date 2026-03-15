import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_theme.dart';
import 'core/firebase_options.dart' as manual;
import 'features/splash_screen.dart';
import 'features/mushaf/mushaf_view.dart';

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
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBE7),
      appBar: AppBar(
        title: Text(
          'LAWHI',
          style: GoogleFonts.inter(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            const SizedBox(height: 30),
            _buildQuickAccessGrid(context),
            const SizedBox(height: 30),
            _buildLastReadCard(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMushaf(context),
        label: const Text('Ouvrir le Mushaf'),
        icon: const Icon(Icons.menu_book),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assalamu Alaikum,',
          style: GoogleFonts.inter(fontSize: 18, color: Colors.black54),
        ),
        Text(
          'Prêt pour votre Hifz ?',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _buildMarkerCard(context, 'Hifz', 'حفظ', Icons.auto_stories, Colors.green),
        _buildMarkerCard(context, 'Murajaa', 'مراجعة', Icons.rebase_edit, Colors.orange),
        _buildMarkerCard(context, 'Tilawa', 'تلاوة', Icons.menu_book, Colors.blue),
        _buildMarkerCard(context, 'Browsing', 'تصفح', Icons.explore, Colors.purple),
      ],
    );
  }

  Widget _buildMarkerCard(
    BuildContext context,
    String title,
    String arabicTitle,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _openMushaf(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(arabicTitle, style: GoogleFonts.amiri(fontSize: 18, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dernière lecture',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sourate Al-Baqarah',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('Thumn 2 - Hizb 1', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 15),
          const LinearProgressIndicator(
            value: 0.2,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  void _openMushaf(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MushafView()));
  }
}


