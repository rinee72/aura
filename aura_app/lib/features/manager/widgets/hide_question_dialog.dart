import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// 질문 숨기기 다이얼로그
/// 
/// WP-4.2: 질문 관리 기능 (숨기기/복구)
/// 
/// 매니저가 질문을 숨길 때 사용하는 다이얼로그입니다.
/// 숨김 사유를 입력하고 템플릿을 선택할 수 있습니다.
class HideQuestionDialog extends StatefulWidget {
  const HideQuestionDialog({
    super.key,
    this.initialReason,
  });

  final String? initialReason;

  /// 다이얼로그 표시 및 결과 반환
  /// 
  /// [context]: BuildContext
  /// [initialReason]: 초기 숨김 사유 (수정 모드일 때)
  /// 
  /// Returns: 숨김 사유 (null이면 취소)
  static Future<String?> show(
    BuildContext context, {
    String? initialReason,
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => HideQuestionDialog(initialReason: initialReason),
    );
  }

  @override
  State<HideQuestionDialog> createState() => _HideQuestionDialogState();
}

class _HideQuestionDialogState extends State<HideQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedTemplate;

  // 숨김 사유 템플릿
  static const List<Map<String, String>> _reasonTemplates = [
    {'value': '욕설/비속어 포함', 'label': '욕설/비속어 포함'},
    {'value': '개인정보 요구', 'label': '개인정보 요구'},
    {'value': '스팸/광고', 'label': '스팸/광고'},
    {'value': '기타', 'label': '기타'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialReason != null) {
      _reasonController.text = widget.initialReason!;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// 템플릿 선택 처리
  void _onTemplateSelected(String? template) {
    setState(() {
      _selectedTemplate = template;
      if (template != null && template != '기타') {
        _reasonController.text = template;
      } else if (template == '기타') {
        _reasonController.clear();
      }
    });
  }

  /// 확인 처리
  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('숨김 사유를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialReason != null ? '숨김 사유 수정' : '질문 숨기기',
        style: AppTypography.h6.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 안내 메시지
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '숨김 처리된 질문은 셀럽 화면에서 즉시 제거됩니다.',
                          style: AppTypography.caption.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 숨김 사유 템플릿
                Text(
                  '숨김 사유 템플릿',
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: _reasonTemplates.map((template) {
                    final value = template['value']!;
                    final isSelected = _selectedTemplate == value;
                    return FilterChip(
                      label: Text(template['label']!),
                      selected: isSelected,
                      onSelected: (_) => _onTemplateSelected(isSelected ? null : value),
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // 숨김 사유 입력 필드
                Text(
                  '숨김 사유 *',
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: '숨김 사유를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  maxLines: 4,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '숨김 사유를 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.initialReason != null ? '수정' : '숨기기'),
        ),
      ],
    );
  }
}

