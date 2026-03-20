import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'doua_speech_helper.dart' if (dart.library.html) 'doua_speech_helper_web.dart';
import '../../core/app_theme.dart';
import '../../core/models/doua_content.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/services/audio_sync_service.dart';

enum ThikrType { sabah, masaa, khatm }

class DouaPage extends StatefulWidget {
  final ThikrType type;
  const DouaPage({super.key, required this.type});

  @override
  State<DouaPage> createState() => _DouaPageState();
}

class _DouaPageState extends State<DouaPage> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer recitationPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  
  bool isPlayingTTS = false;
  bool isRecitationPlaying = false;
  bool isRecitationLoading = false;
  
  int currentPlayingIndex = -1;
  int activeThikrIndex = 0;
  Map<int, int> repetitionCounts = {};
  String? lastError;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initRecitationPlayer();
    _resetCounts();
  }

  void _resetCounts() {
    final thikrs = _getThikrs();
    repetitionCounts = {for (int i = 0; i < thikrs.length; i++) i: 0};
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    if (activeThikrIndex == index) return;
    
    setState(() => activeThikrIndex = index);
    
    // Each item is ~250px, but using an estimate is fine
    const approximateItemHeight = 250.0;
    _scrollController.animateTo(
      index * approximateItemHeight,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _incrementCount(int index) {
    final thikrs = _getThikrs();
    if (index < 0 || index >= thikrs.length) return;
    
    HapticFeedback.lightImpact();
    final current = repetitionCounts[index] ?? 0;
    final max = thikrs[index].count;
    
    if (current < max) {
      setState(() {
        repetitionCounts[index] = current + 1;
      });
    } else {
      setState(() {
        repetitionCounts[index] = 0;
      });
    }
  }

  StreamSubscription<PlayerState>? _playerSubscription;

  Future<void> _initRecitationPlayer() async {
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      }
      
      _playerSubscription = recitationPlayer.playerStateStream.listen((state) {
        if (!mounted) return;
        if (state.processingState == ProcessingState.completed) {
          setState(() { isRecitationPlaying = false; });
        }
      });
    } catch (_) {}
  }

  int currentRepetitionIndex = 0;

  Future<void> _initTts() async {
    try {
      await flutterTts.setLanguage("ar");
      await flutterTts.setSpeechRate(0.45);
      flutterTts.setCompletionHandler(() {
        if (!mounted) return;
        final thikrs = _getThikrs();
        if (currentPlayingIndex < 0 || currentPlayingIndex >= thikrs.length) return;
        
        final thikr = thikrs[currentPlayingIndex];
        
        setState(() {
          currentRepetitionIndex++;
          repetitionCounts[currentPlayingIndex] = currentRepetitionIndex;
          
          if (currentRepetitionIndex < thikr.count) {
            _speak(thikr.text);
          } else if (currentPlayingIndex < thikrs.length - 1) {
            currentPlayingIndex++;
            currentRepetitionIndex = 0;
            _speak(thikrs[currentPlayingIndex].text);
          } else {
            isPlayingTTS = false;
            currentPlayingIndex = -1;
            currentRepetitionIndex = 0;
          }
        });
      });
    } catch (_) {}
  }

  String _stripDiacritics(String text) {
    final diacritics = RegExp(r'[\u064B-\u0652]');
    return text.replaceAll(diacritics, '');
  }

  List<Thikr> _getThikrs() {
    switch (widget.type) {
      case ThikrType.sabah: return DouaContent.morningAthkar;
      case ThikrType.masaa: return DouaContent.eveningAthkar;
      case ThikrType.khatm: return DouaContent.khatmAlQuran;
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case ThikrType.sabah: return 'أذكار الصباح';
      case ThikrType.masaa: return 'أذكار المساء';
      case ThikrType.khatm: return 'دعاء ختم القرآن';
    }
  }

  String _getReciterName() {
    switch (widget.type) {
      case ThikrType.sabah: return 'مشاري العفاسي';
      case ThikrType.masaa: return 'مشاري العفاسي';
      case ThikrType.khatm: return 'العيون الكوشي (بالمغربية)';
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ThikrType.sabah: return Icons.wb_sunny_rounded;
      case ThikrType.masaa: return Icons.dark_mode_rounded;
      case ThikrType.khatm: return Icons.menu_book_rounded;
    }
  }

  List<Color> _getGradient() {
    switch (widget.type) {
      case ThikrType.sabah: return [AppTheme.premiumGold, const Color(0xFFB8860B)];
      case ThikrType.masaa: return [const Color(0xFF312E81), const Color(0xFF1E1B4B)];
      case ThikrType.khatm: return [AppTheme.emeraldGreen, const Color(0xFF014737)];
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _stopRecitation();
    
    // Auto-scroll to the item being spoken
    final thikrs = _getThikrs();
    final index = thikrs.indexWhere((t) => t.text == text);
    if (index != -1) _scrollToIndex(index);

    final plainText = _stripDiacritics(text);
    try {
      if (kIsWeb) {
        DouaSpeechHelper.speakWeb(plainText, 
          onEnd: () {
            if (mounted && isPlayingTTS) {
              final thikrs = _getThikrs();
              final thikr = thikrs[currentPlayingIndex];
              
              setState(() {
                currentRepetitionIndex++;
                repetitionCounts[currentPlayingIndex] = currentRepetitionIndex;
                
                if (currentRepetitionIndex < thikr.count) {
                  _speak(thikr.text);
                } else if (currentPlayingIndex < thikrs.length - 1) {
                  currentPlayingIndex++;
                  currentRepetitionIndex = 0;
                  _speak(thikrs[currentPlayingIndex].text);
                } else {
                  isPlayingTTS = false;
                  currentPlayingIndex = -1;
                  currentRepetitionIndex = 0;
                }
              });
            }
          },
          onError: (err) {
            if (mounted) setState(() => lastError = err);
          }
        );
      } else {
        await flutterTts.speak(plainText);
      }
      if (mounted) setState(() { isPlayingTTS = true; lastError = null; });
    } catch (_) {}
  }

  Future<void> _stopAll() async {
    try {
      await flutterTts.stop();
      DouaSpeechHelper.stopWeb();
      await _stopRecitation();
    } catch (_) {}
    if (mounted) setState(() { isPlayingTTS = false; currentPlayingIndex = -1; activeThikrIndex = 0; });
  }

  Future<void> _stopRecitation() async {
    try {
      await recitationPlayer.stop();
    } catch (_) {}
    if (mounted) setState(() => isRecitationPlaying = false);
  }

  bool _isLoadingSource = false;

  Future<void> _playRecitation() async {
    if (_isLoadingSource) return;
    if (isRecitationPlaying) {
      setState(() => isRecitationPlaying = false);
      recitationPlayer.pause();
      return;
    }
    
    try {
      _isLoadingSource = true;
      await _stopAll();
      if (mounted) setState(() { isRecitationLoading = true; lastError = null; activeThikrIndex = 0; _resetCounts(); });

      String url = '';
      switch (widget.type) {
        case ThikrType.sabah: url = DouaContent.sabahAudioUrl; break;
        case ThikrType.masaa: url = DouaContent.masaaAudioUrl; break;
        case ThikrType.khatm: url = DouaContent.khatmAudioUrl; break;
      }

      if (url.isEmpty) {
        if (mounted) setState(() { isRecitationLoading = false; lastError = "URL introuvable"; });
        _isLoadingSource = false;
        return;
      }

      try {
        if (kIsWeb) {
          // Robust loading for Web with better fallbacks
          try {
            // Disable heavy preloading on web to maintain app fluidness
            await recitationPlayer.setAudioSource(
              AudioSource.uri(Uri.parse(url)),
              preload: false,
            );
          } catch (e) {
            debugPrint('Web Direct Playback Failed: $e');
            // Trying proxy is often worse on modern browsers due to self-CORS, 
            // so we will just retry or rely on the error handling to show "Robot Mode"
          }
        } else {
          // Mobile logic
          final localSyncPath = await AudioSyncService().getLocalPath(widget.type.name);
          if (localSyncPath != null) {
            await recitationPlayer.setAudioSource(AudioSource.file(localSyncPath));
          } else {
            final cacheDir = await getApplicationDocumentsDirectory();
            final cachePath = '${cacheDir.path}/adkar_cache/${widget.type.name}.mp3';
            final dir = Directory(p.dirname(cachePath));
            if (!await dir.exists()) await dir.create(recursive: true);
            await recitationPlayer.setAudioSource(AudioHelper.createAudioSource(url, cachePath));
          }
        }

        if (mounted) {
          setState(() { isRecitationPlaying = true; isRecitationLoading = false; });
          // Fire and forget play to allow UI to remain responsive
          recitationPlayer.play();
        }
      } catch (e) {
        debugPrint('Final Audio Load Error: $e');
        if (mounted) {
          setState(() { 
            lastError = "Échec du chargement audio. Utilisation du Mode Robot..."; 
            isRecitationLoading = false; 
            currentPlayingIndex = 0;
            currentRepetitionIndex = 0;
          });
          _speak(_getThikrs()[currentPlayingIndex].text); 
        }
      }
    } catch (e) {
      debugPrint('General Playback Error: $e');
      if (mounted) {
        setState(() { 
          isRecitationPlaying = false; 
          isRecitationLoading = false; 
          lastError = "Détail: $e"; 
        });
      }
    } finally {
      _isLoadingSource = false;
    }
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _scrollController.dispose();
    flutterTts.stop();
    recitationPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thikrs = _getThikrs();
    final gradient = _getGradient();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                backgroundColor: gradient[0],
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getTitle(), style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: AudioSyncService().isSyncComplete,
                        builder: (context, isDone, child) {
                          if (!isDone) return const SizedBox.shrink();
                          return const Icon(Icons.offline_pin_rounded, color: Colors.lightGreenAccent, size: 18);
                        },
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: gradient),
                    ),
                    child: Stack(
                      children: [
                        Center(child: Opacity(opacity: 0.1, child: Icon(_getIcon(), size: 180, color: Colors.white))),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: isRecitationLoading ? null : _playRecitation,
                                child: Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                  child: isRecitationLoading 
                                    ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white))
                                    : Icon(isRecitationPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 50),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.mic_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text("بصوت: ${_getReciterName()}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [gradient[0], gradient[0].withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: InkWell(
                    onTap: isRecitationLoading ? null : _playRecitation,
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle)),
                            isRecitationLoading 
                              ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Icon(isRecitationPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 40),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.type == ThikrType.khatm ? "الختمة بصوت مغربي" : "أذكار بصوت نقي", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(_getReciterName(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
                            ],
                          ),
                        ),
                        if (isRecitationPlaying) const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 160),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final thikr = thikrs[index];
                      final isCurrent = activeThikrIndex == index;
                      final isCurrentTTS = currentPlayingIndex == index && isPlayingTTS;
                      final count = repetitionCounts[index] ?? 0;
                      final isDone = count >= thikr.count;

                      return GestureDetector(
                        onTap: () {
                          _scrollToIndex(index);
                          _incrementCount(index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isCurrent ? gradient[0].withValues(alpha: 0.6) : (isDone ? Colors.green.withValues(alpha: 0.3) : Colors.transparent), 
                              width: 2
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isCurrent ? gradient[0].withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04), 
                                blurRadius: 20, offset: const Offset(0, 8)
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(thikr.text, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Amiri', fontSize: widget.type == ThikrType.khatm ? 24 : 20, height: 1.8, color: const Color(0xFF1F2937), fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () { setState(() => currentPlayingIndex = index); _speak(thikr.text); },
                                        icon: Icon(isCurrentTTS ? Icons.pause_rounded : Icons.record_voice_over_rounded, size: 16),
                                        label: const Text("Audio Robot", style: TextStyle(fontSize: 11)),
                                        style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                  // Repetition Counter
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDone ? Colors.green.withValues(alpha: 0.1) : (isCurrent ? gradient[0].withValues(alpha: 0.1) : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isDone) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                                        if (isDone) const SizedBox(width: 4),
                                        Text(
                                          '$count / ${thikr.count}',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDone ? Colors.green : (isCurrent ? gradient[0] : Colors.grey[600]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: thikrs.length,
                  ),
                ),
              ),
            ],
          ),
          
          // Floating Caption Bar (Persistent Follow-Along)
          if (isRecitationPlaying || isPlayingTTS)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: _buildCaptionBar(thikrs, gradient),
            ),
        ],
      ),
      bottomNavigationBar: lastError != null 
        ? Container(
            color: Colors.red[100], 
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
            child: Row(
              children: [
                Expanded(child: Text(lastError!, style: TextStyle(color: Colors.red[900], fontSize: 13, fontWeight: FontWeight.bold))),
                TextButton(onPressed: _playRecitation, child: const Text("Réessayer", style: TextStyle(color: Colors.red))),
              ],
            ))
        : null,
    );
  }

  Widget _buildCaptionBar(List<Thikr> thikrs, List<Color> gradient) {
    if (activeThikrIndex < 0 || activeThikrIndex >= thikrs.length) return const SizedBox.shrink();
    final thikr = thikrs[activeThikrIndex];
    final count = repetitionCounts[activeThikrIndex] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gradient[0].withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: activeThikrIndex > 0 ? () => _scrollToIndex(activeThikrIndex - 1) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      thikr.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Répétitions: $count / ${thikr.count}',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: gradient[0]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: activeThikrIndex < thikrs.length - 1 ? () => _scrollToIndex(activeThikrIndex + 1) : null,
              ),
            ],
          ),
          StreamBuilder<Duration>(
            stream: recitationPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: recitationPlayer.durationStream,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0 
                      ? position.inMilliseconds / duration.inMilliseconds 
                      : 0.0;
                  return Container(
                    height: 4,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerRight,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: gradient[0],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause matching the main state
              IconButton(
                icon: Icon(
                  (isRecitationPlaying || isPlayingTTS) ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  color: gradient[0],
                  size: 40,
                ),
                onPressed: () {
                  if (isPlayingTTS) {
                    _stopAll();
                  } else {
                    // Optimistic update
                    if (isRecitationPlaying) {
                      setState(() => isRecitationPlaying = false);
                      recitationPlayer.pause();
                    } else {
                      _playRecitation();
                    }
                  }
                },
              ),
              const SizedBox(width: 20),
              // Manual counter increment
              CircleAvatar(
                radius: 20,
                backgroundColor: gradient[0].withValues(alpha: 0.1),
                child: IconButton(
                  icon: Icon(Icons.add_rounded, color: gradient[0]),
                  onPressed: () => _incrementCount(activeThikrIndex),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
