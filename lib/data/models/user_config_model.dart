import '../../core/constants/api_constants.dart';

class UserConfigModel {
  const UserConfigModel({
    this.provider = ApiConstants.defaultProvider,
    this.apiKey = '',
    this.baseUrl = ApiConstants.defaultBaseUrl,
    this.model = ApiConstants.defaultModel,
    this.customTags = const ['全部', '灵感', '工作', '生活', '学习'],
  });

  final String provider;
  final String apiKey;
  final String baseUrl;
  final String model;
  final List<String> customTags;

  UserConfigModel copyWith({
    String? provider,
    String? apiKey,
    String? baseUrl,
    String? model,
    List<String>? customTags,
  }) {
    return UserConfigModel(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      customTags: customTags ?? this.customTags,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'model': model,
    'customTags': customTags,
  };

  factory UserConfigModel.fromJson(Map<String, dynamic> json) {
    return UserConfigModel(
      provider: json['provider'] as String? ?? ApiConstants.defaultProvider,
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? ApiConstants.defaultBaseUrl,
      model: json['model'] as String? ?? ApiConstants.defaultModel,
      customTags:
          (json['customTags'] as List?)
              ?.whereType<String>()
              .where((tag) => tag.trim().isNotEmpty)
              .toList() ??
          const ['全部', '灵感', '工作', '生活', '学习'],
    );
  }
}
