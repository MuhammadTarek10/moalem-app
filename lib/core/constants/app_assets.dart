class AppAssets {
  static const AppImages images = AppImages._();
  static const AppIcons icons = AppIcons._();
}

class AppImages {
  static const String _imagesPath = 'assets/images';

  const AppImages._();

  String get logo => '$_imagesPath/app_logo.png';
}

class AppIcons {
  static const String _iconsPath = 'assets/icons';

  const AppIcons._();

  String get activitiesMarks => '$_iconsPath/activities-marks.svg';
  String get add => '$_iconsPath/add.svg';
  String get backArrow => '$_iconsPath/back-arrow.svg';
  String get arrowDown => '$_iconsPath/arrow-down.svg';
  String get arrowLeft => '$_iconsPath/arrow-left.svg';
  String get arrowRight => '$_iconsPath/arrow-right.svg';
  String get arrowUp => '$_iconsPath/arrow-up.svg';
  String get attendanceMarks => '$_iconsPath/attendance-marks.svg';
  String get calender => '$_iconsPath/calender.svg';
  String get classesActive => '$_iconsPath/classes-active.svg';
  String get classesInactive => '$_iconsPath/classes-inactive.svg';
  String get contactUs => '$_iconsPath/contact-us.svg';
  String get callUs => '$_iconsPath/call-us.svg';
  String get download => '$_iconsPath/download.svg';
  String get edit => '$_iconsPath/edit.svg';
  String get settings => '$_iconsPath/settings.svg';
  String get star => '$_iconsPath/star.svg';
  String get homeInactive => '$_iconsPath/home-inactive.svg';
  String get homeworkMarks => '$_iconsPath/homework-marks.svg';
  String get inquiry => '$_iconsPath/inquiry.svg';
  String get options => '$_iconsPath/options.svg';
  String get oralMarks => '$_iconsPath/oral-marks.svg';
  String get passwordInviable => '$_iconsPath/password-inviable.svg';
  String get passwordVisible => '$_iconsPath/password-visible.svg';
  String get performanceMarks => '$_iconsPath/performance-marks.svg';
  String get physicalMarks => '$_iconsPath/physical-marks.svg';
  String get print => '$_iconsPath/print.svg';
  String get profileInactive => '$_iconsPath/profile-inactive.svg';
  String get profileActive => '$_iconsPath/profile-active.svg';
  String get refresh => '$_iconsPath/refresh.svg';
  String get remove => '$_iconsPath/remove.svg';
  String get reportsActive => '$_iconsPath/reports-active.svg';
  String get reportsInactive => '$_iconsPath/reports-inactive.svg';
  String get scan => '$_iconsPath/scan.svg';
  String get share => '$_iconsPath/share.svg';
  String get totalMarks => '$_iconsPath/total-marks.svg';
  String get trash => '$_iconsPath/trash.svg';
  String get weekMarks => '$_iconsPath/week-marks.svg';
  String get whatsapp => '$_iconsPath/whatsapp.svg';
}
