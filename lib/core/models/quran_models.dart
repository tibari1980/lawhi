enum Riwaya { warsh, hafs }

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

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'englishName': englishName,
      'englishNameTranslation': englishNameTranslation,
      'numberOfAyahs': numberOfAyahs,
      'revelationType': revelationType,
    };
  }
}

class Ayah {
  final int number;
  final String text;
  final String? translation;
  final String? phonetics;
  final int numberInSurah;
  final int juz;
  final int manzil;
  final int page;
  final int ruku;
  final int hizbQuarter;
  final int surahNumber;
  final String surahName;
  final int? sajda;

  Ayah({
    required this.number,
    required this.text,
    this.translation,
    this.phonetics,
    required this.numberInSurah,
    required this.juz,
    required this.manzil,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
    required this.surahNumber,
    required this.surahName,
    this.sajda,
  });

  // Helper getters for navigation
  int get hizb => ((hizbQuarter - 1) / 4).floor() + 1;
  int get rub => ((hizbQuarter - 1) % 4) + 1;
  int get thumunBase => ((hizbQuarter - 1) % 4) * 2 + 1;
  int get baseThumun => (hizbQuarter - 1) * 2 + 1;
  int get globalThumun => baseThumun;

  int getThumunIndex(List<Ayah> quarterAyahs) {
    final idx = quarterAyahs.indexWhere((a) => a.number == number);
    if (idx == -1) return baseThumun;
    final midPoint = (quarterAyahs.length / 2).floor();
    return idx < midPoint ? baseThumun : baseThumun + 1;
  }

  factory Ayah.fromJson(Map<String, dynamic> json, {String? translation, String? phonetics, int? surahNumber, String? surahName}) {
    return Ayah(
      number: json['number'],
      text: json['text'],
      translation: translation ?? json['translation'],
      phonetics: phonetics ?? json['phonetics'],
      numberInSurah: json['numberInSurah'],
      juz: json['juz'],
      manzil: json['manzil'],
      page: json['page'],
      ruku: json['ruku'],
      hizbQuarter: json['hizbQuarter'],
      surahNumber: surahNumber ?? json['surahNumber'] ?? (json['surah'] != null ? json['surah']['number'] : 0),
      surahName: surahName ?? json['surahName'] ?? (json['surah'] != null ? json['surah']['name'] : ''),
      sajda: json['sajda'] is Map 
          ? json['sajda']['id'] 
          : (json['sajda'] is bool ? (json['sajda'] ? 1 : 0) : json['sajda']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'translation': translation,
      'phonetics': phonetics,
      'numberInSurah': numberInSurah,
      'juz': juz,
      'manzil': manzil,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'sajda': sajda,
    };
  }

  Ayah copyWith({
    int? number,
    String? text,
    String? translation,
    String? phonetics,
    int? numberInSurah,
    int? juz,
    int? manzil,
    int? page,
    int? ruku,
    int? hizbQuarter,
    int? surahNumber,
    String? surahName,
    int? sajda,
  }) {
    return Ayah(
      number: number ?? this.number,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      phonetics: phonetics ?? this.phonetics,
      numberInSurah: numberInSurah ?? this.numberInSurah,
      juz: juz ?? this.juz,
      manzil: manzil ?? this.manzil,
      page: page ?? this.page,
      ruku: ruku ?? this.ruku,
      hizbQuarter: hizbQuarter ?? this.hizbQuarter,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      sajda: sajda ?? this.sajda,
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
