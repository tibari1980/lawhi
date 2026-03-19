import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the active index of the main scaffold's navigation (bottom bar)
/// 0: Home
/// 1: Suwar (Suras)
/// 2: Ahzab (Hizbs)
/// 3: Search
/// 4: Settings
final navigationProvider = StateProvider<int>((ref) => 0);
