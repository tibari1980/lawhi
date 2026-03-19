import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class SiraajErrorView extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  final bool isOffline;

  const SiraajErrorView({
    super.key,
    this.error,
    required this.onRetry,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Illustration container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.emeraldGreen.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 80,
                color: AppTheme.emeraldGreen.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 30),
            
            // Arabic Apology Message
            Text(
              'القُرْآنُ السِّراجُ يَعْتذِرُ لَكُمْ عَنْ هَذَا الخَطَإِ العَرَضِيّ',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.5,
                color: AppTheme.emeraldGreen,
              ),
            ),
            const SizedBox(height: 15),
            
            // French/Sub-title Message
            Text(
              isOffline 
                ? 'Vous êtes hors connexion. Vérifiez votre réseau pour charger de nouveaux contenus.'
                : 'Al-Quran As-Siraj s\'excuse pour ce désagrément occasionnel.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            
            if (error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Retry Button
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة / Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
