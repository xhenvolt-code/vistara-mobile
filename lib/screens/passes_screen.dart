import 'package:flutter/material.dart';

import '../models/access_product.dart';
import '../theme/app_theme.dart';
import '../widgets/preview_notice.dart';
import '../widgets/vistara_header.dart';

class PassesScreen extends StatelessWidget {
  const PassesScreen({
    required this.products,
    required this.isConfigured,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.onSignIn,
    this.onSearch,
    this.displayName,
    super.key,
  });

  final List<AccessProduct> products;
  final bool isConfigured;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onSignIn;
  final VoidCallback? onSearch;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (onSignIn != null)
          VistaraHeader(
            onSignIn: onSignIn!,
            onSearch: onSearch,
            displayName: displayName,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('SIMPLE VIEWING ACCESS'),
              const SizedBox(height: 8),
              Text(
                'Choose your\nmovie-night pass.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Available passes and prices are managed by the Vistara team.',
                style: TextStyle(color: AppTheme.muted, height: 1.5),
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
                      'Build the app with VISTARA_API_BASE_URL to load live '
                      'access products. Passes and prices are not fabricated '
                      'in offline preview mode.',
                )
              else if (products.isEmpty)
                const _EmptyPasses()
              else
                _ProductList(products: products),
              const SizedBox(height: 22),
              PreviewNotice(
                title: 'Checkout not enabled',
                message: isConfigured
                    ? 'MarzPay checkout is not yet enabled on Vistara. '
                          'Passes cannot be purchased in the app.'
                    : 'Passes are visible when the mobile app is connected '
                          'to Vistara. MarzPay checkout is not enabled.',
              ),
              const SizedBox(height: 22),
              const Text(
                'Stories worth staying in for.  ·  Uganda · UGX',
                style: TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products});

  final List<AccessProduct> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: products
          .map(
            (product) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${product.durationDays} '
                            '${product.durationDays == 1 ? 'day' : 'days'} '
                            'of access',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'UGX ${_formatAmount(product.priceUgx)}',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.lock_outline,
                      color: AppTheme.muted,
                      size: 20,
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
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'No access passes are available right now. Please check back soon.',
        style: TextStyle(color: AppTheme.muted, height: 1.5),
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
        Text(message, style: const TextStyle(color: AppTheme.muted)),
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
      style: const TextStyle(
        color: AppTheme.accent,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
      ),
    );
  }
}
