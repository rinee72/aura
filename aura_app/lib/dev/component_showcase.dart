import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../shared/widgets/custom_button.dart';
import '../shared/widgets/custom_text_field.dart';
import '../shared/widgets/custom_card.dart';
import '../shared/widgets/custom_loading.dart';
import '../shared/widgets/custom_error.dart';

/// AURA 컴포넌트 카탈로그 페이지
/// 
/// 모든 디자인 시스템 컴포넌트를 시연하는 개발용 페이지입니다.
class ComponentShowcase extends StatelessWidget {
  const ComponentShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AURA Component Showcase'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildSection(
            title: 'Colors',
            child: _buildColorsSection(),
          ),
          _buildSection(
            title: 'Typography',
            child: _buildTypographySection(),
          ),
          _buildSection(
            title: 'Spacing',
            child: _buildSpacingSection(),
          ),
          _buildSection(
            title: 'Buttons',
            child: _buildButtonsSection(),
          ),
          _buildSection(
            title: 'Text Fields',
            child: _buildTextFieldsSection(),
          ),
          _buildSection(
            title: 'Cards',
            child: _buildCardsSection(),
          ),
          _buildSection(
            title: 'Loading',
            child: _buildLoadingSection(),
          ),
          _buildSection(
            title: 'Error',
            child: _buildErrorSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl,
            bottom: AppSpacing.md,
          ),
          child: Text(
            title,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        child,
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
      ],
    );
  }

  Widget _buildColorsSection() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _buildColorBox('Primary', AppColors.primary),
        _buildColorBox('Secondary', AppColors.secondary),
        _buildColorBox('Error', AppColors.error),
        _buildColorBox('Success', AppColors.success),
        _buildColorBox('Warning', AppColors.warning),
        _buildColorBox('Info', AppColors.info),
        _buildColorBox('Background', AppColors.background),
        _buildColorBox('Surface', AppColors.surface),
      ],
    );
  }

  Widget _buildColorBox(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          name,
          style: AppTypography.caption,
        ),
      ],
    );
  }

  Widget _buildTypographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Heading 1', style: AppTypography.h1),
        Text('Heading 2', style: AppTypography.h2),
        Text('Heading 3', style: AppTypography.h3),
        Text('Heading 4', style: AppTypography.h4),
        Text('Heading 5', style: AppTypography.h5),
        Text('Heading 6', style: AppTypography.h6),
        const SizedBox(height: AppSpacing.sm),
        Text('Body 1', style: AppTypography.body1),
        Text('Body 2', style: AppTypography.body2),
        Text('Body 3', style: AppTypography.body3),
        const SizedBox(height: AppSpacing.sm),
        Text('Label', style: AppTypography.label),
        Text('Caption', style: AppTypography.caption),
        Text('Button', style: AppTypography.button),
      ],
    );
  }

  Widget _buildSpacingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpacingBox('XS', AppSpacing.xs),
        _buildSpacingBox('SM', AppSpacing.sm),
        _buildSpacingBox('MD', AppSpacing.md),
        _buildSpacingBox('LG', AppSpacing.lg),
        _buildSpacingBox('XL', AppSpacing.xl),
        _buildSpacingBox('XXL', AppSpacing.xxl),
      ],
    );
  }

  Widget _buildSpacingBox(String name, double size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: size,
            height: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Text('$name: ${size.toInt()}px', style: AppTypography.body2),
        ],
      ),
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomButton(
          label: 'Primary Button',
          onPressed: () {},
          variant: ButtonVariant.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Secondary Button',
          onPressed: () {},
          variant: ButtonVariant.secondary,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Outlined Button',
          onPressed: () {},
          variant: ButtonVariant.outlined,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Text Button',
          onPressed: () {},
          variant: ButtonVariant.text,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Loading Button',
          onPressed: () {},
          isLoading: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Disabled Button',
          onPressed: null,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Full Width Button',
          onPressed: () {},
          isFullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Small Button',
          onPressed: () {},
          size: ButtonSize.small,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          label: 'Large Button',
          onPressed: () {},
          size: ButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildTextFieldsSection() {
    return Column(
      children: [
        CustomTextField(
          label: 'Label',
          hint: 'Placeholder text',
          controller: TextEditingController(),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'With Prefix Icon',
          hint: 'Search...',
          prefixIcon: const Icon(Icons.search),
          controller: TextEditingController(),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'With Suffix Icon',
          hint: 'Password',
          obscureText: true,
          suffixIcon: const Icon(Icons.visibility_off),
          controller: TextEditingController(),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Multi-line',
          hint: 'Enter multiple lines...',
          maxLines: 3,
          controller: TextEditingController(),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'With Error',
          hint: 'Invalid input',
          errorText: 'This field is required',
          controller: TextEditingController(),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomTextField(
          label: 'Disabled',
          hint: 'Cannot edit',
          enabled: false,
          controller: TextEditingController(),
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return Column(
      children: [
        CustomCard(
          child: Text(
            'Basic Card',
            style: AppTypography.body1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Card with Title',
                style: AppTypography.h6,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This is a card with custom content.',
                style: AppTypography.body2,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CustomCard(
          onTap: () {},
          child: Text(
            'Tappable Card',
            style: AppTypography.body1,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        const CustomLoading(),
        const SizedBox(height: AppSpacing.lg),
        const CustomLoading(message: 'Loading...'),
        const SizedBox(height: AppSpacing.lg),
        const CustomLoading(size: 32.0),
        const SizedBox(height: AppSpacing.lg),
        const CustomLoading(
          size: 32.0,
          message: 'Please wait',
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Column(
      children: [
        CustomError(
          message: 'Something went wrong. Please try again.',
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomError(
          title: 'Connection Error',
          message: 'Unable to connect to the server.',
          onRetry: () {},
        ),
      ],
    );
  }
}

