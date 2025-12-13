import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moalem/core/constants/app_keys.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/services/injection.dart';
import 'package:moalem/core/services/secure_storage_service.dart';
import 'package:moalem/features/activation/domain/usecases/redeem_coupon_usecase.dart';
import 'package:moalem/features/auth/data/models/coupon_model.dart';
import 'package:moalem/features/auth/data/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivationState {
  final AsyncValue<CouponModel?> submissionState;
  final String? userId;
  final String couponCode;

  ActivationState({
    this.submissionState = const AsyncValue.data(null),
    this.userId,
    this.couponCode = '',
  });

  ActivationState copyWith({
    AsyncValue<CouponModel?>? submissionState,
    String? userId,
    String? couponCode,
    bool? contactForCode,
  }) {
    return ActivationState(
      submissionState: submissionState ?? this.submissionState,
      userId: userId ?? this.userId,
      couponCode: couponCode ?? this.couponCode,
    );
  }
}

final activationControllerProvider =
    StateNotifierProvider<ActivationController, ActivationState>((ref) {
      return ActivationController(
        getIt<RedeemCouponUseCase>(),
        getIt<SecureStorageService>(),
      );
    });

class ActivationController extends StateNotifier<ActivationState> {
  final RedeemCouponUseCase _redeemCouponUseCase;
  final SecureStorageService _secureStorageService;

  ActivationController(this._redeemCouponUseCase, this._secureStorageService)
    : super(ActivationState()) {
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userJson = await _secureStorageService.read(AppKeys.user);
    if (userJson != null) {
      try {
        final userModel = UserModel.fromJson(jsonDecode(userJson));
        state = state.copyWith(userId: userModel.id);
      } catch (_) {}
    }
  }

  void setCouponCode(String code) {
    state = state.copyWith(couponCode: code);
  }

  void setContactForCode(bool value) {
    state = state.copyWith(contactForCode: value);
  }

  Future<void> redeemCoupon() async {
    state = state.copyWith(submissionState: const AsyncValue.loading());
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
    const whatsappNumber = '+201022866847';
    final message = state.userId != null
        ? AppStrings.whatsappActivationMessageWithId.tr(args: [state.userId!])
        : AppStrings.whatsappActivationMessage.tr();
    final url = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void reset() {
    state = state.copyWith(submissionState: const AsyncValue.data(null));
  }
}
