import 'package:flutter/services.dart';

class CopyUtils {
  static Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
