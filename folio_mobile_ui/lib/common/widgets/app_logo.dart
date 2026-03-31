import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.materialYou = false,
    this.size,
  });

  final bool materialYou;
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (materialYou) {
      return SvgPicture.asset(
        'assets/svg/menu_icons/monochrome.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.primary,
          BlendMode.srcIn,
        ),
      );
    }

    return Image.asset(
      'assets/icons/ic_rounded.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
