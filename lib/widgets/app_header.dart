import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.softPink, width: 1.5),
            ),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Text('Anne Nails', style: AppTheme.titleStyle.copyWith(fontSize: 19)),
          const Spacer(),
          Material(
            color: AppTheme.button,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.person_outline,
                  color: AppTheme.surface,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
