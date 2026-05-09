import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StickyDialog {
  static Future<bool> confirmDelete(BuildContext context, String title) {
    return confirm(
      context: context,
      title: '确认删除该便签？',
      message: '「$title」删除后可在回收站恢复。',
      icon: Icons.delete_outline_rounded,
      confirmText: '确认删除',
      destructive: true,
    );
  }

  static Future<bool> confirmCompleteTask(
    BuildContext context,
    String title,
  ) {
    return confirm(
      context: context,
      title: '确认完成任务？',
      message: '完成「$title」后会从今日任务中移除，可在任务页继续查看。',
      icon: Icons.task_alt_rounded,
      confirmText: '确认完成',
    );
  }

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    String cancelText = '取消',
    String confirmText = '确认',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBED),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: destructive
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.78),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: destructive
                          ? AppColors.danger
                          : AppColors.accentText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: const TextStyle(
                            height: 1.55,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(cancelText),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: destructive
                            ? AppColors.danger
                            : AppColors.primary,
                        foregroundColor: destructive
                            ? Colors.white
                            : AppColors.accentText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(confirmText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
