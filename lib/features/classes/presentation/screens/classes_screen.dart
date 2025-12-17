import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:moalem/core/constants/app_strings.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navClasses.tr()),
        centerTitle: true,
      ),
      body: Center(child: Text(AppStrings.navClasses.tr())),
    );
  }
}
