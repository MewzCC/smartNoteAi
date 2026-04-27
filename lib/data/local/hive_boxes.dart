import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_keys.dart';

class HiveBoxes {
  static Box<dynamic> get notes => Hive.box<dynamic>(HiveKeys.notesBox);
  static Box<dynamic> get config => Hive.box<dynamic>(HiveKeys.configBox);
}
