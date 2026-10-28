import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VistaraHeader extends StatelessWidget {
  const VistaraHeader({
    required this.onSignIn,
    this.onSearch,
    this.displayName,
    super.key,
  });

  final VoidCallback onSignIn;
  final VoidCallback? onSearch;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          InkWell(
            onTap: onSignIn,
            customBorder: const CircleBorder(),
            child: Semantics(
              button: true,
              label: 'Open your Vistara account',
              child: const CircleAvatar(
                radius: 21,
                backgroundColor: AppTheme.surfaceRaised,
                child: Icon(
                  Icons.person_outline,
                  color: Color(0xFFE4E4E5),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HI, WELCOME',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                displayName?.isNotEmpty == true ? displayName! : 'Movie lover',
                style: TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (onSearch != null)
            IconButton.filled(
              onPressed: onSearch,
              tooltip: 'Search the catalogue',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceRaised,
                foregroundColor: const Color(0xFFF5F5F5),
              ),
              icon: const Icon(Icons.search_rounded),
            )
          else
            TextButton(onPressed: onSignIn, child: const Text('Sign in')),
        ],
      ),
    );
  }
}
