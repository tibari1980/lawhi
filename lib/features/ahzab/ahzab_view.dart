import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/quran_provider.dart';
import '../mushaf/mushaf_view.dart';
import '../../core/settings_provider.dart';

class AhzabView extends ConsumerWidget {
  const AhzabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 60,
        itemBuilder: (context, index) {
          final hizbNumber = index + 1;
          return Semantics(
            label: 'الحزب $hizbNumber',
            button: true,
            child: _HizbCard(hizbNumber: hizbNumber),
          );
        },
      ),
    );
  }
}

class _HizbCard extends ConsumerWidget {
  final int hizbNumber;

  const _HizbCard({required this.hizbNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final firstAyahAsync = ref.watch(hizbFirstAyahProvider(hizbNumber));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final firstThumunOfHizb = (hizbNumber - 1) * 8 + 1;
          ref.read(currentThumunIndexProvider.notifier).state = firstThumunOfHizb;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MushafView(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2), // Very light red
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        '$hizbNumber',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'الحزب $hizbNumber',
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
              firstAyahAsync.when(
                loading: () => const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: Colors.red,
                ),
                error: (err, stack) => Text(
                  'اضغط لعرض محتوى الحزب $hizbNumber كاملاً...',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.amiri(
                    fontSize: settings.fontSize * 0.55,
                    color: Colors.black26,
                  ),
                ),
                data: (ayah) => Text(
                  '${ayah.text}...',
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.amiri(
                    fontSize: settings.fontSize * 0.55,
                    color: const Color(0xFF4B5563),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'بداية الحزب',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_back_ios, size: 10, color: Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
