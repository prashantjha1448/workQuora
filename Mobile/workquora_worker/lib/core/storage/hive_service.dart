import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Boxes used across the app. Keep box count small — each open box has a
/// memory + file-handle cost. We group related cache data into one box
/// per feature instead of one-box-per-entity.
class HiveBoxes {
  HiveBoxes._();
  static const userProfile = 'box_user_profile';
  static const talentList = 'box_talent_list'; // cached Discover results
  static const wallet = 'box_wallet';
  static const notifications = 'box_notifications';
  static const appMeta = 'box_app_meta'; // theme choice, onboarding flags, etc.
}

class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(HiveBoxes.userProfile),
      Hive.openBox(HiveBoxes.talentList),
      Hive.openBox(HiveBoxes.wallet),
      Hive.openBox(HiveBoxes.notifications),
      Hive.openBox(HiveBoxes.appMeta),
    ]);
  }

  /// Call on logout — wipes locally cached (non-secret) data only.
  /// Tokens live in SecureStorageService and are cleared separately.
  static Future<void> clearAllOnLogout() async {
    await Future.wait([
      Hive.box(HiveBoxes.userProfile).clear(),
      Hive.box(HiveBoxes.talentList).clear(),
      Hive.box(HiveBoxes.wallet).clear(),
      Hive.box(HiveBoxes.notifications).clear(),
    ]);
  }
}
