import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeClassItem extends StatelessWidget {
  final String className;
  final String stage;
  final String grade;
  final String subject;
  final VoidCallback onTap;

  const HomeClassItem({
    super.key,
    required this.className,
    required this.stage,
    required this.grade,
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Purple accent strip
              Container(
                width: 4.w,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF7A1C9A,
                  ), // Deep purple color from image
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8.r),
                    bottomRight: Radius.circular(8.r),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      // Arrow icon (Left for RTL context usually, but standard trailing for list tile is typically chevron_right)
                      // The image shows an arrow pointing LEFT '<'. In RTL this means "Go back" or "Details"?
                      // Usually in RTL, the "Next" arrow points to the Left.
                      Icon(
                        Icons.arrow_back_ios_new,
                        size: 16.sp,
                        color: const Color(0xFF7A1C9A),
                      ),
                      const Spacer(),

                      // Text Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            className,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            stage,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            grade,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            subject,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF7A1C9A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
