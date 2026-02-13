import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/constants/app_constants.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/features/activation/domain/usecases/redeem_coupon_usecase.dart';
import 'package:moalem/features/auth/data/models/coupon_model.dart';
import 'package:moalem/features/auth/domain/repositories/user_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivationState {
  final AsyncValue<CouponModel?> submissionState;
  final String? userId;
  final String couponCode;
  final int activationStep;

  ActivationState({
    this.submissionState = const AsyncValue.data(null),
    this.userId,
    this.couponCode = '',
    this.activationStep = 0,
  });

  ActivationState copyWith({
    AsyncValue<CouponModel?>? submissionState,
    String? userId,
    String? couponCode,
    bool? contactForCode,
    int? activationStep,
  }) {
    return ActivationState(
      submissionState: submissionState ?? this.submissionState,
      userId: userId ?? this.userId,
      couponCode: couponCode ?? this.couponCode,
      activationStep: activationStep ?? this.activationStep,
    );
  }
}

final activationControllerProvider =
    StateNotifierProvider.autoDispose<ActivationController, ActivationState>((
      ref,
    ) {
      return ActivationController(
        getIt<RedeemCouponUseCase>(),
        getIt<UserRepository>(),
      );
    });

class ActivationController extends StateNotifier<ActivationState> {
  final RedeemCouponUseCase _redeemCouponUseCase;
  final UserRepository _userRepository;

  ActivationController(this._redeemCouponUseCase, this._userRepository)
    : super(ActivationState()) {
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    print('🔍 [ActivationController] Starting to load user ID...');
    try {
      // Use refreshUser() to force fetching the latest profile from the API
      // even if something is in storage, to ensure we get the correct ID.
      // The AuthInterceptor has been updated to allow this specific path.
      final user = await _userRepository.refreshUser();
      print('✅ [ActivationController] User fetched successfully: ${user.id}');
      state = state.copyWith(userId: user.id);
      print(
        '✅ [ActivationController] State updated with userId: ${state.userId}',
      );
    } catch (e, stackTrace) {
      print('❌ [ActivationController] Error loading user: $e');
      print('Stack trace: $stackTrace');
      // If fetching user fails, userId will remain null
    }
  }

  void setCouponCode(String code) {
    state = state.copyWith(couponCode: code);
  }

  void setContactForCode(bool value) {
    state = state.copyWith(contactForCode: value);
  }

  Future<void> redeemCoupon({required int step}) async {
    state = state.copyWith(
      submissionState: const AsyncValue.loading(),
      activationStep: step,
    );
    try {
      final coupon = await _redeemCouponUseCase(state.couponCode);
      state = state.copyWith(submissionState: AsyncValue.data(coupon));
    } catch (e, stack) {
      state = state.copyWith(submissionState: AsyncValue.error(e, stack));
    }
  }

  Future<void> copyUserId() async {
    if (state.userId != null) {
      await Clipboard.setData(ClipboardData(text: state.userId!));
    }
  }

  Future<void> openWhatsApp() async {
    final message = state.userId != null
        ? AppStrings.whatsappActivationMessageWithId.tr(args: [state.userId!])
        : AppStrings.whatsappActivationMessage.tr();
    final url = Uri.parse(
      'https://wa.me/${AppConstants.contactWhatsAppNumber}?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void reset() {
    state = state.copyWith(
      submissionState: const AsyncValue.data(null),
      couponCode: '',
    );
  }
}
