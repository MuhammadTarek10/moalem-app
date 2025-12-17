import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:moalem/core/constants/app_strings.dart';

class PrintScreen extends StatelessWidget {
  const PrintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.navPrint.tr()), centerTitle: true),
      body: Center(child: Text(AppStrings.navPrint.tr())),
    );
  }
}
