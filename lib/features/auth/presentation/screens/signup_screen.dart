import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/auth/data/models/signup_request.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/widgets/app_button.dart';
import 'package:moalem/shared/widgets/hyperlinks.dart';

import '../controllers/auth_controller.dart';
import '../models/signup_form_data.dart';
import '../widgets/signup_step_one.dart';
import '../widgets/signup_step_three.dart';
import '../widgets/signup_step_two.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _pageController = PageController();
  final _stepOneFormKey = GlobalKey<FormState>();
  final _stepTwoFormKey = GlobalKey<FormState>();
  final _stepThreeFormKey = GlobalKey<FormState>();

  int _currentStep = 0;
  SignupFormData _formData = SignupFormData();

  static const int _totalSteps = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentFormKey {
    switch (_currentStep) {
      case 0:
        return _stepOneFormKey;
      case 1:
        return _stepTwoFormKey;
      case 2:
        return _stepThreeFormKey;
      default:
        return _stepOneFormKey;
    }
  }

  bool _validateCurrentStep() {
    return _currentFormKey.currentState?.validate() ?? false;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    // Additional validation for step 1 - terms agreement
    if (_currentStep == 0 && !_formData.agreeToTerms) {
      context.showErrorSnackBar(AppStrings.agreeTermsRequired.tr());
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _onSignUp();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _onSignUp() {
    if (!_validateCurrentStep()) return;

    final request = SignupRequest(
      email: _formData.email.trim(),
      password: _formData.password.trim(),
      name: _formData.fullName.trim(),
      groupName: _formData.groupName.trim(),
      whatsappNumber: _formData.whatsappNumber.trim(),
      subjects: _formData.subjects,
      governorate: _formData.governorate ?? '',
      educationalAdministration: _formData.educationalAdministration ?? '',
      schools: _formData.schools,
      grades: _formData.grades,
    );

    ref.read(authControllerProvider.notifier).signUp(request);
  }

  void _onDataChanged(SignupFormData data) {
    setState(() {
      _formData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authControllerProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            // New users always go to activation screen
            context.go(AppRoutes.activation);
          }
        },
        error: (error, stack) {
          context.showErrorSnackBar(error.toString());
        },
        loading: () {},
      );
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      appBar: _currentStep > 0
          ? AppBar(
              leading: IconButton(
                onPressed: _previousStep,
                icon: Icon(
                  Platform.isIOS ? Icons.arrow_back_ios_new : Icons.arrow_back,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Page View for steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  // Step 1 - Credentials
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: SignupStepOne(
                      formData: _formData,
                      onDataChanged: _onDataChanged,
                      formKey: _stepOneFormKey,
                    ),
                  ),
                  // Step 2 - Profile Info
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: SignupStepTwo(
                      formData: _formData,
                      onDataChanged: _onDataChanged,
                      formKey: _stepTwoFormKey,
                    ),
                  ),
                  // Step 3 - Location Info
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: SignupStepThree(
                      formData: _formData,
                      onDataChanged: _onDataChanged,
                      formKey: _stepThreeFormKey,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Navigation
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    text: _currentStep < _totalSteps - 1
                        ? AppStrings.nextButton.tr()
                        : AppStrings.signUpButton.tr(),
                    onPressed: _nextStep,
                    isLoading: isLoading,
                  ),
                  if (_currentStep == 0) ...[
                    SizedBox(height: 24.h),
                    TextAndLink(
                      text: AppStrings.haveAccountPrompt.tr(),
                      link: AppRoutes.signIn,
                      hyperLinkText: AppStrings.signInLink.tr(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
