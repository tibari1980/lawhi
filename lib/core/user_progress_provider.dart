import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user_progress.dart';
import 'services/auth_service.dart';

class UserProgressNotifier extends StateNotifier<UserProgress> {
  final FirebaseFirestore? _firestore;
  final String? _uid;

  UserProgressNotifier(this._uid) : _firestore = kIsWeb ? null : FirebaseFirestore.instance, super(UserProgress(
    lastReadThumun: 1,
    hifzCount: 0,
    lastHifzThumun: 0,
    revisionList: [],
  )) {
    if (kIsWeb || _uid == null || _firestore == null) return;
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    if (_firestore == null || _uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (doc.exists && doc.data() != null) {
        state = UserProgress.fromMap(doc.data()!);
      } else {
        // Initialize new user document
        await _saveToFirestore();
      }
    } catch (e) {
      // Handle error (e.g., offline)
    }
  }

  Future<void> _saveToFirestore() async {
    if (kIsWeb || _uid == null || _firestore == null) return;
    try {
      await _firestore.collection('users').doc(_uid).set(state.toMap());
    } catch (e) {
      // Handle error
    }
  }

  void updateLastRead(int thumunIndex) {
    state = state.copyWith(lastReadThumun: thumunIndex);
    _saveToFirestore();
  }

  void addHifzProgress() {
    state = state.copyWith(hifzCount: state.hifzCount + 1);
    _saveToFirestore();
  }

  void updateLastHifz(int thumunIndex) {
    state = state.copyWith(lastHifzThumun: thumunIndex);
    _saveToFirestore();
  }

  void addToRevision(int hizbNumber) {
    if (!state.revisionList.contains(hizbNumber)) {
      state = state.copyWith(revisionList: [...state.revisionList, hizbNumber]);
      _saveToFirestore();
    }
  }
}

final userProgressProvider = StateNotifierProvider<UserProgressNotifier, UserProgress>((ref) {
  if (kIsWeb) {
    // Return a dummy notifier that doesn't use Firebase
    return UserProgressNotifier(null);
  }
  final user = ref.watch(userProvider).value;
  return UserProgressNotifier(user?.uid);
});
