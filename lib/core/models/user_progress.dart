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
}
