import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/core/constants/app_enums.dart';
import 'package:moalem/core/constants/app_strings.dart';
import 'package:moalem/features/attendance/domain/entities/weekly_attendance_entity.dart';
import 'package:moalem/features/attendance/presentation/controllers/attendance_entry_controller.dart';
import 'package:moalem/shared/colors/app_colors.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/screens/loading_screen.dart';

class AttendanceEntryScreen extends ConsumerStatefulWidget {
  final String? classId;

  const AttendanceEntryScreen({super.key, this.classId});

  @override
  ConsumerState<AttendanceEntryScreen> createState() =>
      _AttendanceEntryScreenState();
}

class _AttendanceEntryScreenState extends ConsumerState<AttendanceEntryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceEntryControllerProvider(widget.classId));
    final controller = ref.read(
      attendanceEntryControllerProvider(widget.classId).notifier,
    );

    // Listen for messages
    ref.listen(attendanceEntryControllerProvider(widget.classId), (
      previous,
      next,
    ) {
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        context.showSuccessSnackBar(next.successMessage!);
        controller.clearMessages();
      }
      if (next.error != null && next.error != previous?.error) {
        context.showErrorSnackBar(next.error!);
        controller.clearMessages();
      }
    });

    if (state.isLoading && state.students.isEmpty) {
      return const LoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.attendance.tr()),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Class selector
          _buildClassSelector(context, state, controller),

          // Week selector
          _buildWeekSelector(context, state, controller),

          // Day tabs
          _buildDayTabs(context, state, controller),

          // Bulk actions
          _buildBulkActions(context, state, controller),

          // Search bar
          _buildSearchBar(context, state, controller),

          // Students list
          Expanded(
            child: state.filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.noStudentsTitle.tr(),
                      style: context.bodyLarge.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: state.filteredStudents.length,
                    itemBuilder: (context, index) {
                      final studentInput = state.filteredStudents[index];
                      return _buildStudentAttendanceRow(
                        context,
                        studentInput,
                        state.selectedDay,
                        controller,
                      );
                    },
                  ),
          ),

          // Save button
          if (state.hasUnsavedChanges)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: state.isSaving
                    ? null
                    : () => _showSaveConfirmationDialog(context, controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: state.isSaving
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        AppStrings.saveButton.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassSelector(
    BuildContext context,
    AttendanceEntryState state,
    AttendanceEntryController controller,
  ) {
    if (state.classes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.selectClass.tr(),
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryLightest,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.inactiveBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: state.selectedClass?.id,
                items: state.classes
                    .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.selectClass(value);
                },
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textLight,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(
    BuildContext context,
    AttendanceEntryState state,
    AttendanceEntryController controller,
  ) {
    final dateFormat = DateFormat('d/M', 'ar');
    final weekRange =
        '${dateFormat.format(state.weekStartDate)} - ${dateFormat.format(state.weekEndDate)}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous week button
          IconButton(
            onPressed: () => controller.previousWeek(),
            icon: Icon(Icons.chevron_right, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          // Week range with calendar picker
          InkWell(
            onTap: () => _showWeekPicker(context, state, controller),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primaryLightest,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    weekRange,
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next week button
          IconButton(
            onPressed: () => controller.nextWeek(),
            icon: Icon(Icons.chevron_left, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs(
    BuildContext context,
    AttendanceEntryState state,
    AttendanceEntryController controller,
  ) {
    return Container(
      height: 70.h,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        itemCount: state.weekDays.length,
        itemBuilder: (context, index) {
          final day = state.weekDays[index];
          final isSelected = _isSameDay(day, state.selectedDay);
          final dayName = WeekHelper.getShortDayNameArabic(day.weekday);
          final dateFormat = DateFormat('d', 'ar');

          return GestureDetector(
            onTap: () => controller.selectDay(day),
            child: Container(
              width: 55.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.inactiveBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    dateFormat.format(day),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBulkActions(
    BuildContext context,
    AttendanceEntryState state,
    AttendanceEntryController controller,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: AppColors.surface,
      child: Row(
        children: [
          Text(
            '${AppStrings.markAll.tr()}:',
            style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Row(
              children: [
                _buildBulkActionButton(
                  context,
                  label: AppStrings.present.tr(),
                  color: AppColors.success,
                  onTap: () =>
                      controller.markAllForDay(AttendanceStatus.present),
                ),
                SizedBox(width: 8.w),
                _buildBulkActionButton(
                  context,
                  label: AppStrings.absent.tr(),
                  color: AppColors.error,
                  onTap: () =>
                      controller.markAllForDay(AttendanceStatus.absent),
                ),
                SizedBox(width: 8.w),
                _buildBulkActionButton(
                  context,
                  label: AppStrings.excused.tr(),
                  color: AppColors.warning,
                  onTap: () =>
                      controller.markAllForDay(AttendanceStatus.excused),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: color),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    AttendanceEntryState state,
    AttendanceEntryController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        textAlign: TextAlign.right,
        onChanged: (value) => controller.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: AppStrings.searchStudents.tr(),
          hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14.sp),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: AppColors.textLight.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: AppColors.textLight.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.textLight),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceRow(
    BuildContext context,
    StudentAttendanceInput studentInput,
    DateTime selectedDay,
    AttendanceEntryController controller,
  ) {
    final currentStatus = studentInput.getStatusForDate(selectedDay);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Attendance status buttons
          Row(
            children: [
              _buildStatusButton(
                context,
                status: AttendanceStatus.present,
                currentStatus: currentStatus,
                onTap: () => controller.setAttendanceStatus(
                  studentInput.student.id,
                  AttendanceStatus.present,
                ),
              ),
              SizedBox(width: 8.w),
              _buildStatusButton(
                context,
                status: AttendanceStatus.absent,
                currentStatus: currentStatus,
                onTap: () => controller.setAttendanceStatus(
                  studentInput.student.id,
                  AttendanceStatus.absent,
                ),
              ),
              SizedBox(width: 8.w),
              _buildStatusButton(
                context,
                status: AttendanceStatus.excused,
                currentStatus: currentStatus,
                onTap: () => controller.setAttendanceStatus(
                  studentInput.student.id,
                  AttendanceStatus.excused,
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          // Student name
          Expanded(
            child: Text(
              studentInput.student.name,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Student number
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: AppColors.primaryLightest,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Center(
              child: Text(
                studentInput.student.number.toString(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context, {
    required AttendanceStatus status,
    required AttendanceStatus? currentStatus,
    required VoidCallback onTap,
  }) {
    final isSelected = currentStatus == status;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected
                ? color
                : AppColors.textLight.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: isSelected ? Colors.white : AppColors.textLight,
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.excused:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check;
      case AttendanceStatus.absent:
        return Icons.close;
      case AttendanceStatus.excused:
        return Icons.schedule;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _showWeekPicker(
    BuildContext context,
    AttendanceEntryState state,
    AttendanceEntryController controller,
  ) async {
    final now = DateTime.now();
    final firstAllowedDate = now.subtract(const Duration(days: 7));
    final lastAllowedDate = now.add(const Duration(days: 7));

    // Ensure initial date is within bounds
    DateTime initialDate = state.weekStartDate;
    if (initialDate.isBefore(firstAllowedDate)) {
      initialDate = firstAllowedDate;
    } else if (initialDate.isAfter(lastAllowedDate)) {
      initialDate = lastAllowedDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
      lastDate: lastAllowedDate,
      locale: const Locale('ar'),
    );

    if (picked != null) {
      controller.changeWeek(picked);
    }
  }

  void _showSaveConfirmationDialog(
    BuildContext context,
    AttendanceEntryController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.confirmSave.tr(), textAlign: TextAlign.right),
        content: Text(
          AppStrings.saveAttendanceMessage.tr(),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppStrings.cancelButton.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              context.pop();
              await controller.saveAttendance();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              AppStrings.saveButton.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
