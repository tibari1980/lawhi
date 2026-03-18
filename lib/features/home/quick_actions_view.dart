import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/quran_provider.dart';
import '../mushaf/mushaf_view.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class QuickActionsView extends ConsumerWidget {
  const QuickActionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ref.watch(searchQueryProvider);
    final surahsAsync = ref.watch(surahsProvider);
    final lastRead = ref.watch(lastReadProvider);
    final favoritesCount = ref.watch(favoritesCountProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Search Bar
            Semantics(
              label: 'Recherche de sourate par nom',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: TextField(
                  onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une sourate...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 15),
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (query.isNotEmpty) ...[
              Text(
                'نتائج البحث',
                style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              surahsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
                data: (surahs) {
                  final filtered = surahs.where((s) => s.name.contains(query) || s.englishName.toLowerCase().contains(query.toLowerCase())).toList();
                  if (filtered.isEmpty) return Center(child: Text('لا توجد نتائج', style: GoogleFonts.amiri(fontSize: 18)));
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final surah = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MushafView(), // Navigate to dynamic mushaf
                              ),
                            );
                            // Update last read (mock)
                            ref.read(lastReadProvider.notifier).state = 'سورة ${surah.name}';
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                surah.number.toString(),
                                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          title: Text(surah.name, textAlign: TextAlign.right, style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text(surah.englishName, textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                        ),
                      );
                    },
                  );
                },
              ),
            ] else ...[
              // Grid of Quick Actions with Premium Design
              Text(
                'وصول سريع',
                style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.1,
                children: [
                  _buildPremiumActionCard(
                    context,
                    'آخر قراءة',
                    lastRead,
                    Icons.history_rounded,
                    AppTheme.brandRed,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MushafView())),
                  ),
                  _buildPremiumActionCard(
                    context,
                    'المفضلة',
                    '$favoritesCount سور محفوظة',
                    Icons.bookmark_rounded,
                    AppTheme.brandGreen,
                    () {}, // Add navigation to favorites when ready
                  ),
                  _buildPremiumActionCard(
                    context,
                    'الأذكار',
                    'صباحاً ومساءً',
                    Icons.wb_sunny_rounded,
                    AppTheme.goldAccent,
                    () {},
                  ),
                  _buildPremiumActionCard(
                    context,
                    'الإحصائيات',
                    'مستوى الحفظ',
                    Icons.bar_chart_rounded,
                    Colors.blue[700]!,
                    () {},
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActionCard(
    BuildContext context, 
    String title, 
    String subtitle, 
    IconData icon, 
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.amiri(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
