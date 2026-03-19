import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user_progress.dart';

class UserProgressNotifier extends StateNotifier<UserProgress> {
  UserProgressNotifier() : super(UserProgress(
    lastReadThumun: 1,
    hifzCount: 15,
    lastHifzThumun: 30,
    revisionList: [1, 2, 3],
  ));

  void updateLastRead(int thumunIndex) {
    state = state.copyWith(lastReadThumun: thumunIndex);
  }

  void addHifzProgress() {
    state = state.copyWith(hifzCount: state.hifzCount + 1);
  }

  void addToRevision(int hizbNumber) {
    if (!state.revisionList.contains(hizbNumber)) {
      state = state.copyWith(revisionList: [...state.revisionList, hizbNumber]);
    }
  }
}

final userProgressProvider = StateNotifierProvider<UserProgressNotifier, UserProgress>((ref) {
  return UserProgressNotifier();
});
