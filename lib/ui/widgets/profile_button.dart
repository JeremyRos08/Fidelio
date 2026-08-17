import 'package:flutter/material.dart';

import '../../state/loyalty_controller.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
    required this.controller,
    required this.onPressed,
  });

  final LoyaltyController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final imageBytes = controller.profileImageBytes;
    final name = controller.profileName.trim();
    return IconButton(
      tooltip: 'Mon compte',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: primary.withValues(alpha: .1),
        fixedSize: const Size(46, 46),
      ),
      icon: CircleAvatar(
        radius: 18,
        backgroundColor: imageBytes == null
            ? primary.withValues(alpha: .12)
            : Colors.transparent,
        foregroundImage: imageBytes == null ? null : MemoryImage(imageBytes),
        child: imageBytes != null
            ? null
            : name.isEmpty
            ? Icon(Icons.person_rounded, color: primary, size: 22)
            : Text(
                name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: primary, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }
}
