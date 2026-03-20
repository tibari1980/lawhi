class UserProgress {
  final int lastReadThumun;
  final int hifzCount;
  final int lastHifzThumun;
  final List<int> revisionList;

  UserProgress({
    required this.lastReadThumun,
    required this.hifzCount,
    required this.lastHifzThumun,
    required this.revisionList,
  });

  UserProgress copyWith({
    int? lastReadThumun,
    int? hifzCount,
    int? lastHifzThumun,
    List<int>? revisionList,
  }) {
    return UserProgress(
      lastReadThumun: lastReadThumun ?? this.lastReadThumun,
      hifzCount: hifzCount ?? this.hifzCount,
      lastHifzThumun: lastHifzThumun ?? this.lastHifzThumun,
      revisionList: revisionList ?? this.revisionList,
    );
  }
  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      lastReadThumun: map['lastReadThumun'] ?? 1,
      hifzCount: map['hifzCount'] ?? 0,
      lastHifzThumun: map['lastHifzThumun'] ?? 0,
      revisionList: List<int>.from(map['revisionList'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastReadThumun': lastReadThumun,
      'hifzCount': hifzCount,
      'lastHifzThumun': lastHifzThumun,
      'revisionList': revisionList,
    };
  }
}
