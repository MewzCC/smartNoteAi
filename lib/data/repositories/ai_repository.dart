import '../../core/network/ai_client.dart';
import '../models/user_config_model.dart';

class AiRepository {
  const AiRepository();

  Future<List<GeneratedPlan>> generate({
    required UserConfigModel config,
    required String prompt,
  }) {
    return AiClient(config).generate(prompt);
  }
}
