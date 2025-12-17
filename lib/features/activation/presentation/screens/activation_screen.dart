import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/activation/presentation/controllers/activation_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/widgets/app_button.dart';
import 'package:moalem/shared/widgets/text_input.dart';
import 'package:moalem/shared/widgets/whatsapp_button.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();

  void _copyUserId() {
    ref.read(activationControllerProvider.notifier).copyUserId();
    context.showSuccessSnackBar(AppStrings.codeCopied.tr());
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      ref.read(activationControllerProvider.notifier).redeemCoupon();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activationState = ref.watch(activationControllerProvider);
    final submissionState = activationState.submissionState;
    final isLoading = submissionState is AsyncLoading;

    // Listen to activation state changes
    ref.listen(activationControllerProvider, (previous, next) {
      final prevSubmission = previous?.submissionState;
      final nextSubmission = next.submissionState;

      // Only react if submission state changed
      if (prevSubmission != nextSubmission) {
        nextSubmission.when(
          data: (coupon) {
            if (coupon != null) {
              context.showSuccessSnackBar(AppStrings.activationSuccess.tr());
              context.go(AppRoutes.home);
            }
          },
          error: (error, stack) {
            context.showErrorSnackBar(error.toString());
          },
          loading: () {},
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),

                // Logo
                Image.asset(AppAssets.images.logo, height: 120.h, width: 120.w),
                SizedBox(height: 16.h),

                // Title
                Text(
                  AppStrings.appTitle.tr(),
                  textAlign: TextAlign.center,
                  style: context.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),

                // Description
                Text(
                  AppStrings.activationDescription.tr(),
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                    color: AppColors.textSubtitle,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),

                // User ID Card
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.yourIdLabel.tr(),
                        style: context.bodyMedium.copyWith(
                          color: AppColors.textSubtitle,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _copyUserId,
                            icon: Icon(
                              Icons.copy_outlined,
                              color: AppColors.textSubtitle,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              activationState.userId ?? '------',
                              textAlign: TextAlign.center,
                              style: context.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Enter Code Label
                Text(
                  AppStrings.enterCodeLabel.tr(),
                  style: context.bodyMedium.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),

                // Code Input Field
                AppTextFormField(
                  onChanged: (value) => ref
                      .read(activationControllerProvider.notifier)
                      .setCouponCode(value),
                  keyboardType: TextInputType.text,
                  hint: AppStrings.enterCodeHint.tr(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.requiredField.tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Bottom Buttons
                Row(
                  children: [
                    // WhatsApp Button
                    Expanded(
                      flex: 2,
                      child: WhatsAppButton(
                        onPressed: () => ref
                            .read(activationControllerProvider.notifier)
                            .openWhatsApp(),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Submit Button
                    Expanded(
                      child: AppButton(
                        text: AppStrings.submitButton.tr(),
                        onPressed: _onSubmit,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
