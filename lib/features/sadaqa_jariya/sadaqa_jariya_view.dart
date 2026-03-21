import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';

class SadaqaJariyaView extends StatelessWidget {
  const SadaqaJariyaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   _buildDedicationCard(context),
                  const SizedBox(height: 32),
                  _buildDuaSection(context),
                  const SizedBox(height: 32),
                  _buildDeveloperInfo(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.emeraldGreen,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'صدقة جارية',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.emeraldGreen, Color(0xFF064E3B)],
                ),
              ),
            ),
            // Decorative pattern
            Positioned(
              right: -50,
              top: -50,
              child: Icon(
                Icons.mosque_rounded,
                size: 250,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildDedicationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppTheme.premiumGold,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'في ذكرى والدي العزيز',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.emeraldGreen,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'زروال محمد',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Text(
            'Zeroual Mohamed',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.calendar_month_rounded, 'تاريخ الوفاة', '١٠ مايو ٢٠٢٥ - ٥:٠٠ صباحاً'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_rounded, 'مكان الوفاة', 'الدار البيضاء، المغرب'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.home_rounded, 'مكان الميلاد', 'سيدي عبدالخالق (أولاد أبو)'),
          const SizedBox(height: 32),
          const Text(
            'كان رجلاً خيراً، محباً للناس، سباقاً للصدقة. هذا العمل صدقة جارية تنير قبره بإذن الله.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              height: 1.6,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: AppTheme.premiumGold, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuaSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.emeraldGreen, Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppTheme.richGold, size: 40),
          const SizedBox(height: 16),
          const Text(
            'دعاء للمتوفى',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '« اللهم اغفر له وارحمه، وعافه واعف عنه، وأكرم نزله، ووسع مدخله، واغسله بالماء والثلج والبرد، ونقه من الخطايا كما ينقى الثوب الأبيض من الدنس، وأبدله داراً خيراً من داره، وأهلاً خيراً من أهله، وأدخله الجنة وأعذه من عذاب القبر ومن عذاب النار »',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              height: 1.8,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جزاكم الله خيراً على دعائكم', style: TextStyle(fontFamily: 'Amiri')),
                  backgroundColor: AppTheme.emeraldGreen,
                ),
              );
            },
            icon: const Icon(Icons.favorite_rounded, color: AppTheme.emeraldGreen),
            label: const Text(
              'أميــن',
              style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfo(BuildContext context) {
    return Column(
      children: [
        const Text(
          'تواصل مع المطور',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'زروال تيباري (الابن)',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            color: Color(0xFF4B5563),
          ),
        ),
        const Text(
          'Engineer Developer - Franco-Moroccan',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildContactIconButton(Icons.email_rounded, 'mailto:tibarinewdzign@gmail.com'),
            const SizedBox(width: 20),
            _buildContactIconButton(Icons.phone_rounded, 'tel:+33625491640'),
          ],
        ),
      ],
    );
  }

  Widget _buildContactIconButton(IconData icon, String url) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.emeraldGreen),
        onPressed: () {
          // In a real app, use url_launcher
          HapticFeedback.lightImpact();
        },
      ),
    );
  }
}
