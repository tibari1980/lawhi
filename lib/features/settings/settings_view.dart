import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/settings_provider.dart';
import '../../core/models/quran_models.dart';
import '../sadaqa_jariya/sadaqa_jariya_view.dart';

class SettingsView extends ConsumerStatefulWidget {
  final bool showAppBar;
  const SettingsView({super.key, this.showAppBar = true});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: widget.showAppBar ? AppBar(
        title: Text(
          'إعدادات',
          style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.emeraldGreen,
        elevation: 0,
        leading: canPop ? IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
      ) : null,
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // Riwaya Selection Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('الرواية'),
                const SizedBox(height: 20),
                _buildRadioGroup<Riwaya>(
                  options: [Riwaya.hafs, Riwaya.warsh],
                  labels: ['رواية حفص', 'رواية ورش'],
                  currentValue: settings.riwaya,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setRiwaya(v!),
                ),
              ],
            ),
          ),

          // Appearance Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('مظهر'),
                const SizedBox(height: 20),
                // Font Size Slider
                Slider(
                  value: settings.fontSize,
                  min: 20,
                  max: 100,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setFontSize(v),
                  activeColor: Colors.blue,
                ),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('تغيير لون الخلفية', style: TextStyle(color: Colors.blue, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                // Preview Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
                  decoration: BoxDecoration(
                    color: settings.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'فَأَسْقَيْنَاكُمُوهُ...',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontFamily: 'Amiri',
                          fontSize: settings.fontSize * 0.7,
                          color: settings.backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (settings.showPhonetics) ...[
                        const SizedBox(height: 10),
                        Text(
                          '[ Fa\'asqaynakumuhu ]',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: (settings.fontSize * 0.7) * 0.5,
                            color: AppTheme.richGold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // White/Black Toggles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildThemeToggle('أسود', const Color(0xFF0F172A), settings),
                    const SizedBox(width: 15),
                    _buildThemeToggle('أبيض', const Color(0xFFF1F5F9), settings),
                  ],
                ),
                const SizedBox(height: 25),
                _buildSectionSubtitle('اخترنا لك'),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRecommendedColor(const Color(0xFF0F172A), settings),
                    _buildRecommendedColor(const Color(0xFF064E3B), settings),
                    _buildRecommendedColor(const Color(0xFFE2E8F0), settings),
                  ],
                ),
              ],
            ),
          ),

          // Scroll Speed Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('سرعة التمرير'),
                const SizedBox(height: 20),
                Slider(
                  value: settings.scrollSpeed,
                  min: 0,
                  max: 20,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setScrollSpeed(v),
                  activeColor: Colors.blue,
                ),
                Center(
                  child: Text(
                    '${settings.scrollSpeed.toInt()}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Languages & Translation Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('اللغات والترجمة'),
                const SizedBox(height: 20),
                
                const Text('لغة التطبيق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildRadioGroup<String>(
                  options: ['English', 'Français', 'العربية'],
                  currentValue: settings.language,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setLanguage(v!),
                ),
                
                const SizedBox(height: 25),
                const Text('add phonetics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildRadioGroup<bool>(
                  options: [true, false],
                  labels: ['Yes', 'No'],
                  currentValue: settings.showPhonetics,
                  onChanged: (v) => ref.read(settingsProvider.notifier).setShowPhonetics(v!),
                ),
              ],
            ),
          ),
          // About / Sadaqa Jariya Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('عن التطبيق'),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'صدقة جارية',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'في ذكرى الوالد زروال محمد رحمه الله',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 14, color: Colors.grey),
                  ),
                  leading: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppTheme.premiumGold, size: 24),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SadaqaJariyaView()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRadioGroup<T>({
    required List<T> options,
    List<String>? labels,
    required T currentValue,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final label = labels != null ? labels[index] : option.toString();
        final isSelected = currentValue == option;
        
        return InkWell(
          onTap: () => onChanged(option),
          child: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Amiri', // Added fontFamily
                    fontSize: 16,
                    color: isSelected ? Colors.blue : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Radio<T>(
                  value: option,
                  // ignore: deprecated_member_use
                  groupValue: currentValue,
                  // ignore: deprecated_member_use
                  onChanged: onChanged,
                  activeColor: Colors.blue,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        );
      }).reversed.toList(), // Reverse for RTL feel
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontFamily: 'Amiri', fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
    );
  }

  Widget _buildSectionSubtitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildThemeToggle(String label, Color color, AppSettings settings) {
    bool isSelected = settings.backgroundColor == color;
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setBackgroundColor(color),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isSelected ? Colors.blue : Colors.black12, width: 2),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.black54,
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedColor(Color color, AppSettings settings) {
    bool isSelected = settings.backgroundColor == color;
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setBackgroundColor(color),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.blue, width: 3) : Border.all(color: Colors.black.withValues(alpha: 0.1)),
          boxShadow: [
            if (isSelected) BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10)
          ],
        ),
      ),
    );
  }
}
