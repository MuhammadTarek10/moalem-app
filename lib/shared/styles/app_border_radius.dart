import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppBorderRadius {
  // Content Preview Border Radius: 80px on left side only (top-left and bottom-left)
  // This creates rounded corners on the left side: border-radius: 80px 0px 0px 80px
  static BorderRadius get contentPreview => BorderRadius.only(
    topLeft: Radius.circular(80.r),
    bottomLeft: Radius.circular(80.r),
  );
}
