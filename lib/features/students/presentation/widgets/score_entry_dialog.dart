import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moalem/shared/colors/app_colors.dart';

class ScoreEntryDialog extends StatefulWidget {
  final String studentName;
  final int maxScore;
  final int initialScore;

  const ScoreEntryDialog({
    super.key,
    required this.studentName,
    required this.maxScore,
    this.initialScore = 0,
  });

  @override
  State<ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _QrScoreEntryButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  const _QrScoreEntryButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: EdgeInsets.all(8.w),
        child: Icon(
          icon,
          color: enabled
              ? AppColors.textMain
              : AppColors.textLight.withValues(alpha: 0.3),
          size: 24.sp,
        ),
      ),
    );
  }
}

class _ScoreEntryDialogState extends State<ScoreEntryDialog> {
  late int _currentScore;

  @override
  void initState() {
    super.initState();
    _currentScore = widget.initialScore;
  }

  void _increment() {
    if (_currentScore < widget.maxScore) {
      setState(() {
        _currentScore++;
      });
    }
  }

  void _decrement() {
    if (_currentScore > 0) {
      setState(() {
        _currentScore--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.studentName,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Row(
                    children: [
                      _QrScoreEntryButton(
                        icon: Icons.remove,
                        onPressed: _decrement,
                        enabled: _currentScore > 0,
                      ),
                      SizedBox(width: 20.w),
                      Text(
                        '$_currentScore',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      SizedBox(width: 20.w),
                      _QrScoreEntryButton(
                        icon: Icons.add,
                        onPressed: _increment,
                        enabled: _currentScore < widget.maxScore,
                      ),
                    ],
                  ),
                ),
                Text(
                  'أدخل الدرجة',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _currentScore),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'إدخال',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
