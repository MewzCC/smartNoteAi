import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../data/local/hive_database.dart';
import '../../data/repositories/note_repository.dart';
import '../utils/device_utils.dart';

class AppBootstrap {
  AppBootstrap._();

  static Future<void>? _ready;

  static Future<void> start() {
    return _ready ??= _init();
  }

  static Future<void> get ready => start();

  static Future<void> _init() async {
    await initializeDateFormatting('zh_CN');
    await Hive.initFlutter();
    await HiveDatabase.open();
    await NotificationService.instance.init();
    await NotificationService.instance.reschedulePending(
      NoteRepository().loadNotes(),
    );
  }
}
