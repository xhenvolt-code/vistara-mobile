import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/access_product.dart';
import '../services/vistara_api.dart';
import '../theme/app_theme.dart';

class SubscriptionCheckoutSheet extends StatefulWidget {
  const SubscriptionCheckoutSheet({
    required this.api,
    required this.product,
    required this.onRefreshAccount,
    required this.onOpenAccount,
    super.key,
  });

  final VistaraApi api;
  final AccessProduct product;
  final Future<void> Function() onRefreshAccount;
  final Future<void> Function() onOpenAccount;

  @override
  State<SubscriptionCheckoutSheet> createState() =>
      _SubscriptionCheckoutSheetState();
}

class _SubscriptionCheckoutSheetState extends State<SubscriptionCheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  String? _purchaseMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
      _purchaseMessage = null;
    });

    try {
      final purchase = await widget.api.createSubscriptionPurchase(
        productId: widget.product.id,
        phoneNumber: _phoneController.text,
      );
      if (!mounted) return;
      setState(() => _purchaseMessage = purchase.message);
      await widget.onRefreshAccount();
    } on VistaraApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vistara;
    final purchaseStarted = _purchaseMessage != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                purchaseStarted ? 'Payment request sent' : 'Start subscription',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.product.name} · ${widget.product.termLabel}',
                style: TextStyle(color: palette.muted),
              ),
              const SizedBox(height: 6),
              Text(
                'UGX ${_formatAmount(widget.product.priceUgx)} · one-time '
                'mobile-money payment',
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!purchaseStarted) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[+0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Ugandan mobile number',
                    hintText: '+256700000000',
                    helperText: 'A MarzPay approval prompt will be sent.',
                  ),
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^\+256\d{9}$').hasMatch(value.trim())) {
                      return 'Enter a number in +256XXXXXXXXX format.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your subscription starts only after MarzPay confirms '
                  'payment. It does not renew automatically.',
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_purchaseMessage case final message?) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(message),
                ),
                const SizedBox(height: 10),
                Text(
                  'Follow any mobile-money instructions. Do not retry while '
                  'this payment is pending; access is granted only after '
                  'server-side verification.',
                  style: TextStyle(color: palette.muted, height: 1.5),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : purchaseStarted
                      ? () async {
                          Navigator.of(context).pop();
                          await widget.onRefreshAccount();
                          await widget.onOpenAccount();
                        }
                      : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          purchaseStarted
                              ? 'Check subscription status'
                              : 'Pay with MarzPay',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
