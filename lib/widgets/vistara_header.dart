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
          Semantics(
            image: true,
            label: 'Vistara',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/images/vistara_app_icon.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HI, WELCOME',
                style: TextStyle(
                  color: context.vistara.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                displayName?.isNotEmpty == true ? displayName! : 'Movie lover',
                style: TextStyle(
                  color: context.vistara.onBackground,
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
                backgroundColor: context.vistara.surfaceRaised,
                foregroundColor: context.vistara.onBackground,
              ),
              icon: const Icon(Icons.search_rounded),
            ),
          IconButton(
            onPressed: onSignIn,
            tooltip: displayName?.isNotEmpty == true
                ? 'Open your Vistara account'
                : 'Sign in to Vistara',
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
    );
  }
}
