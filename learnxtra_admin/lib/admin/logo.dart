import 'package:flutter/material.dart';

class LearnXtraLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showTagline;

  const LearnXtraLogo({
    super.key,
    this.size = 60,
    this.showText = true,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Logo.png',
      height: size,
      fit: BoxFit.contain,
    );
  }
}
