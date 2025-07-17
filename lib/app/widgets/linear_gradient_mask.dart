import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class LinearGradientMask extends StatelessWidget {
  const LinearGradientMask({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(-0.35, -1.272),
          end: Alignment(0.84, 0.87),
          colors: [AppColors.gradient1, AppColors.gradient2],
          stops: [0.0, 1.0],
          tileMode: TileMode.mirror,
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
