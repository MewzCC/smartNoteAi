import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/local/hive_database.dart';
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
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    await NotificationService.instance.init();
  }
}
