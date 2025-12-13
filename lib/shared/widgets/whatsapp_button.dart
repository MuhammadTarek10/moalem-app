import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moalem/core/constants/app_assets.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/widgets/primary_button.dart';

class WhatsAppButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const WhatsAppButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      onPressed: onPressed,
      text: AppStrings.contactWhatsapp.tr(),
      backgroundColor: AppColors.whatsapp,
      foregroundColor: Colors.white,
      icon: SvgPicture.asset(
        AppAssets.icons.whatsapp,
        width: 24.w,
        height: 24.h,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
      textStyle: context.bodyLarge.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
