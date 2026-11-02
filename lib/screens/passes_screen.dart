import 'package:flutter/material.dart';

import '../models/access_product.dart';
import '../services/vistara_api.dart';
import '../theme/app_theme.dart';
import '../widgets/preview_notice.dart';
import '../widgets/subscription_checkout_sheet.dart';
import '../widgets/vistara_header.dart';

class PassesScreen extends StatelessWidget {
  const PassesScreen({
    required this.products,
    required this.api,
    required this.isConfigured,
    required this.isSignedIn,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.onSignIn,
    this.onRefreshAccount,
    this.onOpenAccount,
    this.onSearch,
    this.displayName,
    super.key,
  });

  final List<AccessProduct> products;
  final VistaraApi api;
  final bool isConfigured;
  final bool isSignedIn;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Future<void> Function()? onSignIn;
  final Future<void> Function()? onRefreshAccount;
  final Future<void> Function()? onOpenAccount;
  final VoidCallback? onSearch;
  final String? displayName;

  Future<void> _startSubscription(
    BuildContext context,
    AccessProduct product,
  ) async {
    if (!isSignedIn) {
      await onSignIn?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in before starting a subscription.'),
          ),
        );
      }
      return;
    }
    if (onRefreshAccount == null || onOpenAccount == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SubscriptionCheckoutSheet(
        api: api,
        product: product,
        onRefreshAccount: onRefreshAccount!,
        onOpenAccount: onOpenAccount!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (onSignIn != null)
          VistaraHeader(
            onSignIn: () async => onSignIn?.call(),
            onSearch: onSearch,
            displayName: displayName,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('FLEXIBLE VIEWING PLANS'),
              const SizedBox(height: 8),
              Text(
                'Choose your\nsubscription.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Choose a viewing term and pay securely with MarzPay mobile money.',
                style: TextStyle(color: context.vistara.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error != null)
                _PassesError(message: error!, onRetry: onRetry)
              else if (!isConfigured)
                const PreviewNotice(
                  title: 'Vistara server not configured',
                  message:
                      'Connect to a Vistara API origin to load live subscription '
                      'plans. Plans and prices are not fabricated in '
                      'offline preview mode.',
                )
              else if (products.isEmpty)
                const _EmptyPasses()
              else
                _ProductList(
                  products: products,
                  onSubscribe: (product) =>
                      _startSubscription(context, product),
                ),
              const SizedBox(height: 22),
              if (isConfigured && products.isNotEmpty)
                const Text(
                  'Subscriptions are prepaid for the displayed term and do '
                  'not auto-renew. Payment is confirmed by Vistara before '
                  'viewing access is granted.',
                ),
              const SizedBox(height: 22),
              Text(
                'Stories worth staying in for.  ·  Uganda · UGX',
                style: TextStyle(color: context.vistara.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products, required this.onSubscribe});

  final List<AccessProduct> products;
  final ValueChanged<AccessProduct> onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: products
          .map(
            (product) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.vistara.accent.withValues(
                              alpha: 0.13,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.subscriptions_outlined,
                            color: context.vistara.accent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  color: context.vistara.onBackground,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${product.termLabel} · '
                                '${product.durationDays} '
                                '${product.durationDays == 1 ? 'day' : 'days'}',
                                style: TextStyle(
                                  color: context.vistara.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'UGX ${_formatAmount(product.priceUgx)}',
                                style: TextStyle(
                                  color: context.vistara.accent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => onSubscribe(product),
                        child: const Text('Subscribe'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _EmptyPasses extends StatelessWidget {
  const _EmptyPasses();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: context.vistara.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'No subscription plans are available right now. Please check back soon.',
        style: TextStyle(color: context.vistara.muted, height: 1.5),
      ),
    );
  }
}

class _PassesError extends StatelessWidget {
  const _PassesError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: context.vistara.muted)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}

String _formatAmount(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.vistara.accent,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
      ),
    );
  }
}
