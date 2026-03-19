import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/settings_provider.dart';
import '../../../core/models/quran_models.dart';

class RiwayaSelectionDialog extends ConsumerWidget {
  const RiwayaSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRiwaya = ref.watch(settingsProvider.select((s) => s.riwaya));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تحديد الرواية',
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            _buildOption(
              context,
              ref,
              label: 'رواية ورش',
              value: Riwaya.warsh,
              isSelected: currentRiwaya == Riwaya.warsh,
            ),
            const Divider(),
            _buildOption(
              context,
              ref,
              label: 'رواية حفص',
              value: Riwaya.hafs,
              isSelected: currentRiwaya == Riwaya.hafs,
            ),
            const Divider(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required Riwaya value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(settingsProvider.notifier).setRiwaya(value);
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.amiri(
            fontSize: 22,
            color: Colors.blue,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

void showRiwayaSelectionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const RiwayaSelectionDialog(),
  );
}
