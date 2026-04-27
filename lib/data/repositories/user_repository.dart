import '../../core/constants/hive_keys.dart';
import '../local/hive_boxes.dart';
import '../models/user_config_model.dart';

class UserRepository {
  UserConfigModel loadConfig() {
    final raw = HiveBoxes.config.get(HiveKeys.userConfig);
    if (raw is! Map) return const UserConfigModel();
    return UserConfigModel.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> saveConfig(UserConfigModel config) {
    return HiveBoxes.config.put(HiveKeys.userConfig, config.toJson());
  }
}
