import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/copy_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/app_scaffold.dart';
import 'ai_settings_page.dart';

class ProviderGuidePage extends StatelessWidget {
  const ProviderGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      activePath: '/home',
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const StickySliverAppBar(
              title: '接入教程',
              showBack: true,
              showSearch: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final provider = aiProviders[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(provider.tip),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _open(provider.homepage),
                                child: Text(
                                  provider.homepage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.accentText,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: '复制',
                              onPressed: () async {
                                await CopyUtils.copy(provider.homepage);
                                ToastUtils.show('已复制');
                              },
                              icon: const Icon(Icons.copy_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }, childCount: aiProviders.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await CopyUtils.copy(url);
      ToastUtils.show('无法打开，已复制链接');
    }
  }
}
