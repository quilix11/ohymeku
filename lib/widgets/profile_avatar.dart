import 'package:flutter/material.dart';
import 'app_components.dart';

const profileColors = [
  Color(0xFF49319A),
  Color(0xFF356A61),
  Color(0xFF994A66),
  Color(0xFF88622F),
  Color(0xFF3C638F),
  Color(0xFF77528C)
];

class ProfileAvatar extends StatelessWidget {
  final int avatar, color;
  final double size;
  const ProfileAvatar(
      {super.key, required this.avatar, required this.color, this.size = 64});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: profileColors[color.clamp(0, 5)].withValues(alpha: .14),
          shape: BoxShape.circle,
          border: Border.all(
              color: profileColors[color.clamp(0, 5)].withValues(alpha: .3))),
      child: Icon(profileIcons[avatar.clamp(0, profileIcons.length - 1)],
          size: size * .46,
          color: Theme.of(context).brightness == Brightness.dark
              ? Color.lerp(profileColors[color.clamp(0, 5)], Colors.white, .55)
              : profileColors[color.clamp(0, 5)]));
}
