import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moalem/shared/extensions/context.dart';
import 'package:moalem/shared/styles/app_text.dart';

class TextAndLink extends StatelessWidget {
  const TextAndLink({
    super.key,
    required this.text,
    required this.link,
    required this.hyperLinkText,
  });
  final String text;
  final String link;
  final String hyperLinkText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: context.bodySmall),
        TextButton(
          onPressed: () => context.push(link),
          child: Text(hyperLinkText, style: context.bodySmall.hyperLinkText),
        ),
      ],
    );
  }
}
