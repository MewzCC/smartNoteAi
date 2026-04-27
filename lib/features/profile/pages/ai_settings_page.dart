import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../core/widgets/sticky_button.dart';
import '../../../core/widgets/sticky_input.dart';
import '../../../data/models/ai_provider_model.dart';
import '../../../data/models/user_config_model.dart';
import '../../../shared/components/app_scaffold.dart';
import '../provider/profile_provider.dart';

class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  late String _provider;
  late final TextEditingController _apiKey;
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;

  @override
  void initState() {
    super.initState();
    final config = ref.read(smartNoteProvider).config;
    _provider = config.provider;
    _apiKey = TextEditingController(text: config.apiKey);
    _baseUrl = TextEditingController(text: config.baseUrl);
    _model = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _apiKey.dispose();
    _baseUrl.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = aiProviders.firstWhere(
      (item) => item.name == _provider,
      orElse: () => aiProviders.first,
    );
    final notConfigured =
        _apiKey.text.trim().isEmpty ||
        _baseUrl.text.trim().isEmpty ||
        _model.text.trim().isEmpty;
    return AppScaffold(
      activePath: '/home',
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
          children: [
            const StickyAppBar(
              title: 'AI 服务商',
              showBack: true,
              showSearch: false,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notConfigured) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.noteYellow.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '请先完成 API Key、Base URL 和 Model 配置。未配置时无法使用 AI 生成功能。',
                              style: TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    '选择服务商',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in aiProviders)
                        ChoiceChip(
                          label: Text(item.name),
                          selected: item.name == _provider,
                          onSelected: (_) => _select(item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(title: 'API Key', desc: '从服务商控制台创建密钥后粘贴到这里。'),
                  StickyInput(
                    controller: _apiKey,
                    hint: 'sk-...',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _FieldLabel(
                    title: 'Base URL',
                    desc: '需要填写完整接口地址，通常以 /v1 结尾。',
                  ),
                  StickyInput(
                    controller: _baseUrl,
                    hint: selected.baseUrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _FieldLabel(title: 'Model', desc: '填写服务商支持的模型名称。'),
                  StickyInput(
                    controller: _model,
                    hint: selected.model,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selected.tip,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StickyButton(
                    label: '保存配置',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => context.push('/profile/provider-guide'),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('查看接入教程'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _select(AiProviderModel provider) {
    setState(() {
      _provider = provider.name;
      _baseUrl.text = provider.baseUrl;
      _model.text = provider.model;
    });
  }

  Future<void> _save() async {
    if (_apiKey.text.trim().isEmpty ||
        _baseUrl.text.trim().isEmpty ||
        _model.text.trim().isEmpty) {
      ToastUtils.show('请完整填写 API Key、Base URL 和 Model');
      setState(() {});
      return;
    }
    final config = UserConfigModel(
      provider: _provider,
      apiKey: _apiKey.text.trim(),
      baseUrl: _baseUrl.text.trim(),
      model: _model.text.trim(),
    );
    await ref.read(smartNoteProvider.notifier).saveConfig(config);
    if (!mounted) return;
    final goAi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配置已保存'),
        content: const Text('要现在进入 AI 智能页，和助手进行一次对话体验吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('去体验'),
          ),
        ],
      ),
    );
    if (goAi == true && mounted) {
      context.go('/ai');
    } else {
      ToastUtils.show('已保存');
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title, required this.desc});

  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

const aiProviders = [
  AiProviderModel(
    name: 'OpenAI',
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-4o-mini',
    homepage: 'https://platform.openai.com/api-keys',
    tip: '创建 API key 后填入上方输入框。',
  ),
  AiProviderModel(
    name: 'Anthropic',
    baseUrl: 'https://api.anthropic.com/v1',
    model: 'claude-3-5-haiku-latest',
    homepage: 'https://console.anthropic.com/settings/keys',
    tip: '创建 API key 后，模型名按官方控制台填写。',
  ),
  AiProviderModel(
    name: 'Google Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    model: 'gemini-1.5-flash',
    homepage: 'https://aistudio.google.com/app/apikey',
    tip: 'Gemini OpenAI 兼容接口可使用此 Base URL。',
  ),
  AiProviderModel(
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    model: 'deepseek-chat',
    homepage: 'https://platform.deepseek.com/api_keys',
    tip: 'DeepSeek 使用 OpenAI 兼容接口格式。',
  ),
  AiProviderModel(
    name: '硅基流动',
    baseUrl: 'https://api.siliconflow.cn/v1',
    model: 'Qwen/Qwen2.5-7B-Instruct',
    homepage: 'https://cloud.siliconflow.cn/account/ak',
    tip: '硅基流动使用 OpenAI 兼容接口，Base URL 请保留末尾 /v1。',
  ),
  AiProviderModel(
    name: 'Moonshot',
    baseUrl: 'https://api.moonshot.cn/v1',
    model: 'moonshot-v1-8k',
    homepage: 'https://platform.moonshot.cn/console/api-keys',
    tip: 'Moonshot API Key 在控制台创建。',
  ),
  AiProviderModel(
    name: '智谱AI',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    model: 'glm-4-flash',
    homepage: 'https://open.bigmodel.cn/usercenter/apikeys',
    tip: '智谱AI 使用官方开放平台密钥。',
  ),
  AiProviderModel(
    name: '通义千问',
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    model: 'qwen-plus',
    homepage: 'https://bailian.console.aliyun.com/?apiKey=1',
    tip: '通义千问可使用 DashScope 兼容模式。',
  ),
];
