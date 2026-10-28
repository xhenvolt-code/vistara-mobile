import 'package:flutter/material.dart';

import '../models/account_session.dart';
import '../theme/app_theme.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    required this.session,
    required this.onSignOut,
    super.key,
  });

  final AccountSession session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final entitlement = session.entitlement;
    return Scaffold(
      appBar: AppBar(title: const Text('My Vistara account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.surfaceRaised,
            child: Text(
              _initials(session.user.name, session.user.email),
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            session.user.name.isEmpty ? session.user.email : session.user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            session.user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted),
          ),
          if (session.user.accountStatus == 'SUSPENDED') ...[
            const SizedBox(height: 18),
            const _StatusNotice(
              message:
                  'This account is suspended. Contact Vistara support for '
                  'assistance.',
            ),
          ],
          const SizedBox(height: 28),
          const _SectionTitle('Your access'),
          const SizedBox(height: 10),
          if (entitlement == null)
            const _InformationCard(
              icon: Icons.lock_outline,
              title: 'No active access pass',
              subtitle: 'Active passes appear here after payment is verified.',
            )
          else
            _InformationCard(
              icon: Icons.confirmation_number_outlined,
              title: entitlement.productName,
              subtitle: 'Active until ${_formatDate(entitlement.expiresAt)}',
            ),
          const SizedBox(height: 24),
          const _SectionTitle('Purchase history'),
          const SizedBox(height: 10),
          if (session.purchases.isEmpty)
            const _InformationCard(
              icon: Icons.receipt_long_outlined,
              title: 'No purchases yet',
              subtitle: 'Verified pass purchases will appear here.',
            )
          else
            ...session.purchases.map(
              (purchase) => _InformationCard(
                icon: Icons.receipt_long_outlined,
                title: purchase.productName,
                subtitle:
                    '${purchase.currency} '
                    '${_formatAmount(purchase.amountUgx)} · '
                    '${purchase.status.toLowerCase()}',
                trailing: _formatDate(purchase.createdAt),
              ),
            ),
          const SizedBox(height: 26),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accent),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.muted)),
        trailing: trailing == null
            ? null
            : Text(
                trailing!,
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.muted)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

String _initials(String name, String email) {
  final label = name.trim().isEmpty ? email : name.trim();
  final words = label.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  return words
      .take(2)
      .map((word) => word.characters.first.toUpperCase())
      .join();
}

String _formatAmount(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

String _formatDate(DateTime date) {
  final localDate = date.toLocal();
  return '${localDate.day.toString().padLeft(2, '0')}/'
      '${localDate.month.toString().padLeft(2, '0')}/'
      '${localDate.year}';
}
