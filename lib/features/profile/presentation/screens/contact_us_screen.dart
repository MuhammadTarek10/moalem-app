import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/shared/widgets/app_app_bar.dart';
import 'package:moalem/shared/widgets/whatsapp_button.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: AppStrings.profileMenuContactUs.tr()),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          children: [
            // Header Image or Icon could go here
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 60.w,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 24.h),

            Text(
              AppStrings.contactUsSubtitle.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 32.h),

            const WhatsAppButton(),
          ],
        ),
      ),
    );
  }
}
