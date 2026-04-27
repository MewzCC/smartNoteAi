import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_keys.dart';

class HiveDatabase {
  static Future<void> open() async {
    await Hive.openBox<dynamic>(HiveKeys.notesBox);
    await Hive.openBox<dynamic>(HiveKeys.configBox);
  }
}
