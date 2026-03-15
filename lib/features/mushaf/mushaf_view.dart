import 'package:flutter/material.dart';
import 'mushaf_page.dart';

class MushafView extends StatefulWidget {
  const MushafView({super.key});

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  final PageController _pageController = PageController();
  
  // Mock data for now
  final List<Map<String, dynamic>> _thumns = const [
    {
      'title': 'الحزب الأول - الثمن الأول',
      'ayahs': [
        'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        'الرَّحْمَنِ الرَّحِيمِ',
        'مَالِكِ يَوْمِ الدِّينِ',
        'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
        'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
        'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      ],
    },
    {
      'title': 'الحزب الأول - الثمن الثاني',
      'ayahs': [
        'الم',
        'ذَلِكَ الْكِتَابُ لاَ رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ',
        'الَّذِينَ يُؤْمِنُونَ بِالْغَيْبِ وَيُقِيمُونَ الصَّلاةَ وَمِمَّا رَزَقْنَاهُمْ يُنفِقُونَ',
        'والَّذِينَ يُؤْمِنُونَ بِمَا أُنزِلَ إِلَيْكَ وَمَا أُنزِلَ مِن قَبْلِكَ وَبِالآخِرَةِ هُمْ يُوقِنُونَ',
        'أُوْلَئِكَ عَلَى هُدًى مِّن رَّبِّهِمْ وَأُوْلَئِكَ هُمُ الْمُفْلِحُونَ',
      ],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصحف - لوح مروكي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _thumns.length,
        itemBuilder: (context, index) {
          final thumn = _thumns[index];
          return MushafPage(
            thumnTitle: thumn['title'] as String,
            ayahs: List<String>.from(thumn['ayahs'] as Iterable),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () {
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }),
            const Text('Hizb 1 - Thumn 1'),
            IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () {
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }),
          ],
        ),
      ),
    );
  }
}
