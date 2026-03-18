import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/settings_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light gray background for settings
      appBar: AppBar(
        title: Text(
          'إعدادات',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // Appearance Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('مظهر'),
                const SizedBox(height: 10),
                Semantics(
                  label: 'تعديل حجم الخط, الحالي ${settings.fontSize.toInt()}',
                  value: settings.fontSize.toString(),
                  child: Slider(
                    value: settings.fontSize,
                    min: 20,
                    max: 100,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setFontSize(v),
                    activeColor: Colors.blue,
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('تغيير لون الخلفية', style: TextStyle(color: Colors.blue)),
                  ),
                ),
                const SizedBox(height: 10),
                ExcludeSemantics(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: settings.backgroundColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'فَأَسْقَيْنَاكُمُوهُ...',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: settings.fontSize * 0.8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorOption(const Color(0xFF0F172A), 'لون أسود', settings),
                    _buildColorOption(const Color(0xFF064E3B), 'لون أخضر', settings),
                    _buildColorOption(const Color(0xFFF1F5F9), 'لون أبيض', settings, isLight: true),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSectionSubtitle('اخترنا لك'),
              ],
            ),
          ),

          // Scroll Speed Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('سرعة التمرير'),
                const SizedBox(height: 10),
                Semantics(
                  label: 'تعديل سرعة التمرير الآلي, السرعة الحالية ${settings.scrollSpeed.toInt()}',
                  value: settings.scrollSpeed.toString(),
                  child: Slider(
                    value: settings.scrollSpeed,
                    min: 0,
                    max: 20,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setScrollSpeed(v),
                    activeColor: Colors.blue,
                  ),
                ),
                Center(
                  child: Text(
                    '${settings.scrollSpeed.toInt()}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Languages Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('اللغات والترجمة'),
                const SizedBox(height: 15),
                const Text('لغة التطبيق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSectionSubtitle(String title) {
    return Text(
      title,
      style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildColorOption(Color color, String label, AppSettings settings, {bool isLight = false}) {
    bool isSelected = settings.backgroundColor == color;
    return Column(
      children: [
        GestureDetector(
          onTap: () => ref.read(settingsProvider.notifier).setBackgroundColor(color),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? Colors.blue : Colors.black12, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: isLight ? Colors.black54 : Colors.blue)),
      ],
    );
  }
}
