import 'package:intl/intl.dart';

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String formatNoteTime(DateTime value) {
  final today = dateOnly(DateTime.now());
  final day = dateOnly(value);
  final time = DateFormat('HH:mm').format(value);
  if (day.isAtSameMomentAs(today)) return '今天 $time';
  if (day.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
    return '昨天 $time';
  }
  return DateFormat('M月d日 HH:mm', 'zh_CN').format(value);
}

String formatFullTime(DateTime value) =>
    DateFormat('yyyy/MM/dd HH:mm', 'zh_CN').format(value);
