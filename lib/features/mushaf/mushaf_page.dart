import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MushafPage extends StatelessWidget {
  final String thumnTitle;
  final List<String> ayahs;
  final Color backgroundColor;

  const MushafPage({
    super.key,
    required this.thumnTitle,
    required this.ayahs,
    this.backgroundColor = const Color(0xFFF9FBE7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          // Header: Thumn Title
          Text(
            thumnTitle,
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const Divider(thickness: 1, color: Colors.black12),
          const SizedBox(height: 20),
          
          // Body: Verses
          Expanded(
            child: SingleChildScrollView(
              child: RichText(
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  children: _buildVerses(),
                  style: GoogleFonts.amiri(
                    fontSize: 28,
                    height: 2.0,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          
          // Footer: Progress
          const SizedBox(height: 10),
          const Text(
            '1 / 80', // Placeholder for Thumn number
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildVerses() {
    List<TextSpan> spans = [];
    for (int i = 0; i < ayahs.length; i++) {
      spans.add(TextSpan(text: '${ayahs[i]} '));
      spans.add(
        TextSpan(
          text: ' ﴾${i + 1}﴿ ',
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      );
    }
    return spans;
  }
}
