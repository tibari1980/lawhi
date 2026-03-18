class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
      numberOfAyahs: json['numberOfAyahs'],
      revelationType: json['revelationType'],
    );
  }
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final int? sajda; // Some ayahs have sajda info

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    this.sajda,
  });

  // Helper getters for navigation
  int get hizb => ((hizbQuarter - 1) / 4).floor() + 1;
  int get rub => ((hizbQuarter - 1) % 4) + 1;
  // In Warsh tradition: 1 Hizb = 8 Thumuns = 4 Rob3s.
  // 1 Rob3 = 2 Thumuns.
  // Since the API only gives hizbQuarter (which are Quarters/Rob3s),
  // we'll calculate the base Thumun (1-8) for each Hizb.
  int get thumunBase => ((hizbQuarter - 1) % 4) * 2 + 1;
  int get globalThumun => (hizbQuarter - 1) * 2 + 1;

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'],
      text: json['text'],
      numberInSurah: json['numberInSurah'],
      juz: json['juz'],
      manzil: json['manzil'],
      page: json['page'],
      ruku: json['ruku'],
      hizbQuarter: json['hizbQuarter'],
      sajda: json['sajda'] is Map ? json['sajda']['id'] : null,
    );
  }
}

class Hizb {
  final int number;
  final List<Ayah> ayahs;

  Hizb({
    required this.number,
    required this.ayahs,
  });
}
