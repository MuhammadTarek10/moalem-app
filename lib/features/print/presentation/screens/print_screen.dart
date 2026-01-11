import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/print/presentation/widgets/print_option_card.dart';
import 'package:moalem/shared/colors/app_colors.dart';

class PrintScreen extends StatelessWidget {
  const PrintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navPrint.tr()),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Student Scores Card
          PrintOptionCard(
            title: AppStrings.printStudentScores.tr(),
            icon: Icons.analytics_outlined,
            iconColor: AppColors.primary,
            onTap: () {
              // Navigate to print options screen for scores
              context.push(
                AppRoutes.printOptionsPath(
                  classId: '', // Will be selected in next screen
                  printType: 'scores',
                ),
              );
            },
          ),

          // Attendance Card
          PrintOptionCard(
            title: AppStrings.printAttendance.tr(),
            icon: Icons.event_available_outlined,
            iconColor: AppColors.primary,
            onTap: () {
              // Navigate to print options screen for attendance
              context.push(
                AppRoutes.printOptionsPath(
                  classId: '', // Will be selected in next screen
                  printType: 'attendance',
                ),
              );
            },
          ),

          // QR Codes Card
          PrintOptionCard(
            title: AppStrings.printQRCodes.tr(),
            icon: Icons.qr_code_2_outlined,
            iconColor: AppColors.primary,
            onTap: () {
              // Show coming soon dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppStrings.comingSoon.tr()),
                  content: Text(AppStrings.comingSoonSubtitle.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.closeButton.tr()),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
