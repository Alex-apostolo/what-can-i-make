import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/features/payment/domain/payment_service.dart';
import 'package:what_can_i_make/features/payment/models/payment_package.dart';

class PaymentScreen extends StatefulWidget {
  static const routeName = '/payment';

  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentService _paymentService;
  late final ErrorHandler _errorHandler;

  @override
  void initState() {
    super.initState();
    _paymentService = context.read<PaymentService>();
    _errorHandler = context.read<ErrorHandler>();
  }

  Future<void> _purchasePackage(PaymentPackage package) async {
    final result = await _paymentService.purchaseRequestPackage(package);

    _errorHandler.handleEither(result);

    if (result.isRight()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully purchased ${package.requestCount} API requests!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate successful purchase
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Listen to payment service changes
    final paymentService = context.watch<PaymentService>();
    final isProcessing = paymentService.purchasePending;
    final purchaseError = paymentService.purchaseError;
    final packages = paymentService.getAvailablePackages();
    final storeAvailable = paymentService.isAvailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Plan')),
      body:
          isProcessing
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a Package',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Purchase additional API requests to continue using the app',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),

                    if (purchaseError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Card(
                          color: colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Error: $purchaseError',
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (!storeAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Card(
                          color: colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.store_mall_directory,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Store is currently unavailable. Please try again later.',
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    ...packages.map(
                      (package) =>
                          _buildPackageCard(package, colorScheme, theme),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoSection(theme, colorScheme),
                  ],
                ),
              ),
    );
  }

  Widget _buildPackageCard(
    PaymentPackage package,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            package.isBestValue
                ? BorderSide(color: colorScheme.primary, width: 2)
                : BorderSide.none,
      ),
      child: Stack(
        children: [
          if (package.isBestValue)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'BEST VALUE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(package.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '\$${package.price.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _purchasePackage(package),
                      icon: Icon(
                        Icons.shopping_cart,
                        color: colorScheme.onPrimary,
                      ),
                      label: const Text('Purchase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About API Requests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.info_outline,
              title: 'What are API requests?',
              description:
                  'API requests are used when analyzing images or generating recipes.',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.refresh,
              title: 'Do requests expire?',
              description:
                  'No, your purchased requests never expire and can be used anytime.',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.security,
              title: 'Secure payments',
              description:
                  'All transactions are secure and processed through the App Store or Google Play.',
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
