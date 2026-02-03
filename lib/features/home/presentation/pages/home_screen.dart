import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_routes.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/core/entities/user.dart';
import 'package:moalem/core/utils/error_handler.dart';
import 'package:moalem/core/utils/license_checker.dart';
import 'package:moalem/features/classes/presentation/controllers/classes_controller.dart';
import 'package:moalem/features/classes/presentation/screens/add_or_edit_class_dialog.dart';
import 'package:moalem/features/classes/presentation/screens/class_details_screen.dart';
import 'package:moalem/features/home/presentation/controllers/home_controller.dart';
import 'package:moalem/features/home/presentation/widgets/home_class_item.dart';
import 'package:moalem/features/home/presentation/widgets/home_header.dart'; // Add import
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/screens/error_screen.dart';
import 'package:moalem/shared/screens/loading_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).fetchAndStoreUser();
    });
  }

  Future<void> _showAddClassDialog(BuildContext context) async {
    final result = await AddOrEditClassDialog.show(context);
    if (result != null && result.isValid) {
      ref
          .read(classesControllerProvider.notifier)
          .addClass(
            name: result.className!,
            stage: result.educationalStage!,
            grade: result.gradeLevel!,
            subject: result.subject!,
            semester: result.semester!,
            school: result.school!,
            evaluationGroup: result.evaluationGroup!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(homeControllerProvider, (previous, next) {
      next.whenData((user) {
        if (user != null &&
            !LicenseChecker.isLicenseValid(user.licenseExpiresAt)) {
          context.go(AppRoutes.activation);
        }
      });
    });

    final homeState = ref.watch(homeControllerProvider);
    final classesState = ref.watch(classesControllerProvider);

    return Scaffold(
      body: homeState.when(
        loading: () => const LoadingScreen(),
        error: (err, stack) => ErrorScreen(
          message: ErrorHandler.getErrorMessage(err),
          onRetry: () =>
              ref.read(homeControllerProvider.notifier).fetchAndStoreUser(),
        ),
        data: (user) {
          return Column(
            children: [
              HomeHeader(user: user),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      // Header Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title
                          Text(
                            AppStrings.classroomsList.tr(),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),

                          // Add Class Button
                          ElevatedButton.icon(
                            onPressed: () => _showAddClassDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF6A1B9A,
                              ), // Purple color
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(
                              AppStrings.addClass.tr(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: 16.h),

                      // Classes List
                      Expanded(
                        child: classesState.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(
                            child: Text(ErrorHandler.getErrorMessage(err)),
                          ),
                          data: (classes) {
                            if (classes.isEmpty) {
                              return Center(
                                child: Text(
                                  AppStrings.noClassesTitle.tr(),
                                  style: TextStyle(color: AppColors.textLight),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: classes.length,
                              itemBuilder: (context, index) {
                                final classEntity = classes[index];
                                return HomeClassItem(
                                  className: classEntity.name,
                                  stage: classEntity.stage,
                                  grade: classEntity.grade,
                                  subject: classEntity.subject,
                                  onTap: () {
                                    context.pushNewScreen(
                                      ClassDetailsScreen(id: classEntity.id),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
