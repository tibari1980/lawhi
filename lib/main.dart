import 'dart:ui';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'core/services/audio_sync_service.dart';
import 'core/app_theme.dart';
import 'core/firebase_options.dart' as manual;
import 'features/splash_screen.dart';
import 'features/mushaf/mushaf_view.dart';
import 'features/ahzab/ahzab_view.dart';
import 'features/suwar/suwar_view.dart';
import 'features/home/quick_actions_view.dart';
import 'features/home/home_view.dart';
import 'features/settings/settings_view.dart';
import 'core/settings_provider.dart';
import 'core/navigation_provider.dart';
import 'core/quran_provider.dart';
import 'core/models/quran_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Silence all debugPrint calls on Web to keep the console perfectly clean as requested by the user
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  final sharedPreferences = await SharedPreferences.getInstance();

  try {
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
    
    // Enable offline persistence only on mobile
    if (!kIsWeb) {
      cloud_firestore.FirebaseFirestore.instance.settings = const cloud_firestore.Settings(
        persistenceEnabled: true, 
        cacheSizeBytes: cloud_firestore.Settings.CACHE_SIZE_UNLIMITED
      );
    }
  } catch (e) {
    // Silent catch to avoid console noise on unsupported platforms
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SirajApp(),
    ),
  );
}

class SirajApp extends ConsumerWidget {
  const SirajApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'القرآن السراج',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreenEntry(),
    );
  }
}

class SplashScreenEntry extends ConsumerStatefulWidget {
  const SplashScreenEntry({super.key});

  @override
  ConsumerState<SplashScreenEntry> createState() => _SplashScreenEntryState();
}

class _SplashScreenEntryState extends ConsumerState<SplashScreenEntry> {
  @override
  void initState() {
    super.initState();
    // Initialize Services during splash for offline readiness
    Future(() async {
      await ref.read(audioServiceProvider).init();
      await ref.read(quranServiceProvider).initialize();
      // Background sync for Adkar (only on mobile to avoid web overhead)
      if (!kIsWeb) {
        AudioSyncService().preDownloadAll();
      }
      
      if (mounted) {
        // Navigate as soon as initialized, with a minimum visual delay for the logo
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScaffold()),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);
    final settings = ref.watch(settingsProvider);
    final isLight = settings.backgroundColor.computeLuminance() > 0.5;
    final contentColor = isLight ? const Color(0xFF1F2937) : Colors.white;

    // Listen for audio errors (e.g., offline)
    ref.listen(audioErrorProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next, style: const TextStyle(fontFamily: 'Amiri', color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    });

    const List<Widget> pages = [
      HomeView(),
      SuwarView(),
      AhzabView(),
      QuickActionsView(),
      SettingsView(showAppBar: false),
    ];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: settings.backgroundColor,
          appBar: currentIndex == 0 ? null : AppBar(
            title: Text(
              'القرآن السراج',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isLight ? AppTheme.emeraldGreen : Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: settings.backgroundColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_rounded, color: AppTheme.emeraldGreen),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const MushafView()),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: contentColor.withValues(alpha: 0.1)),
            ),
          ),
          extendBody: true, // Allow body behind nav bar
          body: IndexedStack(
            index: currentIndex,
            children: pages,
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCustomNavItem(context, ref, 0, Icons.home_rounded, 'الرئيسية', ''),
                      _buildCustomNavItem(context, ref, 1, Icons.menu_book_rounded, 'السور', '114'),
                      _buildCustomNavItem(context, ref, 2, Icons.format_list_bulleted_rounded, 'الأحزاب', '60'),
                      _buildCustomNavItem(context, ref, 3, Icons.search_rounded, 'البحث', ''),
                      _buildCustomNavItem(context, ref, 4, Icons.settings_rounded, 'الإعدادات', ''),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Mini Player (Now at the ROOT level to ensure hit testing works correctly on Web)
        Consumer(
          builder: (context, ref, child) {
            final playingAyah = ref.watch(currentPlayingAyahProvider);
            if (playingAyah == null) return const SizedBox.shrink();
            
            return Positioned(
              bottom: 110,
              left: 24,
              right: 24,
              child: _buildMiniPlayer(context, ref, playingAyah),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniPlayer(BuildContext context, WidgetRef ref, Ayah playingAyah) {
    final audioPlayer = ref.read(audioServiceProvider);
    
    return Semantics(
      label: 'مشغل القرآن الكريم',
      child: GestureDetector(
        onTap: () {
          // Prevent click-through to background elements (HomeView cards)
          // You could also add navigation to MushafView here IF specificially clicked 
          // on the background, but the user wants to AVOID redirection when clicking X.
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: audioPlayer.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0 
                          ? position.inMilliseconds / duration.inMilliseconds 
                          : 0.0;
                      return Container(
                        height: 3,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(color: AppTheme.richGold),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: AppTheme.richGold, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StreamBuilder<PlayerState>(
                              stream: audioPlayer.playerStateStream,
                              builder: (context, snapshot) {
                                final currentAyah = ref.watch(currentPlayingAyahProvider);
                                final processingState = snapshot.data?.processingState;
                                String status = 'قيد التشغيل...';
                                if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering || currentAyah?.number == -1) {
                                  status = 'جاري التحميل...';
                                }
                                return Text(
                                  status,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                                );
                              },
                            ),
                            // The Close Button
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              splashRadius: 16,
                              onPressed: () {
                                // Stop audio and clear state
                                ref.read(currentPlayingAyahProvider.notifier).stop();
                              },
                            ),
                          ],
                        ),
                        Text(
                          playingAyah.number == -1 
                            ? playingAyah.surahName 
                            : '${playingAyah.surahName} • آية ${playingAyah.numberInSurah}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Verset précédent',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                      onPressed: () => ref.read(currentPlayingAyahProvider.notifier).playPrevious(),
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      // Use optimistic provider for instant feedback, but listen to stream to keep it in sync
                      final isPlayingOptimistic = ref.watch(optimisticIsPlayingProvider);
                      final audioService = ref.read(audioServiceProvider);
                      
                      // Keep optimistic in sync with actual player state, unless a manual toggle is in progress
                      ref.listen(isPlayingProvider, (previous, next) {
                        final actual = next.value ?? false;
                        final isManualToggle = ref.read(isManualToggleActiveProvider);
                        
                        if (!isManualToggle && actual != ref.read(optimisticIsPlayingProvider)) {
                          ref.read(optimisticIsPlayingProvider.notifier).state = actual;
                        }
                      });

                      return StreamBuilder<PlayerState>(
                        stream: audioService.playerStateStream,
                        builder: (context, snapshot) {
                          final processingState = snapshot.data?.processingState;
                          
                          if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                            return const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            );
                          }
                          
                          return Semantics(
                            label: isPlayingOptimistic ? 'Pause' : 'Lecture',
                            button: true,
                            child: IconButton(
                              iconSize: 40,
                              padding: EdgeInsets.zero,
                              splashRadius: 24,
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isPlayingOptimistic ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                  key: ValueKey(isPlayingOptimistic),
                                  color: AppTheme.richGold,
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ref.read(currentPlayingAyahProvider.notifier).togglePlayPause();
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Semantics(
                    label: 'Verset suivant',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                      onPressed: () => ref.read(currentPlayingAyahProvider.notifier).playNext(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavItem(BuildContext context, WidgetRef ref, int index, IconData icon, String label, String badge) {
    final currentIndex = ref.watch(navigationProvider);
    bool isSelected = currentIndex == index;
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
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(navigationProvider.notifier).state = index;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon, 
                  size: 28, 
                  color: isSelected ? AppTheme.emeraldGreen : Colors.grey.shade400
                ),
                if (badge.isNotEmpty)
                  Positioned(
                    top: -5,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.emeraldGreen : Colors.grey.shade400,
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
