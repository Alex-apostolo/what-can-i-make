import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/features/payment/domain/payment_service.dart';
import 'package:what_can_i_make/features/payment/models/payment_package.dart';
import 'package:what_can_i_make/features/payment/presentation/components/credit_pack_card.dart';
import 'package:what_can_i_make/features/payment/presentation/components/credits_header.dart';
import 'package:what_can_i_make/features/payment/presentation/components/info_section.dart';
import 'package:what_can_i_make/features/payment/presentation/components/processing_view.dart';
import 'package:what_can_i_make/features/payment/presentation/components/store_error_card.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';

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
              'Successfully purchased ${package.requestCount} AI credits!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to payment service changes
    final paymentService = context.watch<PaymentService>();
    final isProcessing = paymentService.purchasePending;
    final purchaseError = paymentService.purchaseError;
    final packages = paymentService.getAvailablePackages();
    final storeAvailable = paymentService.isAvailable;

    // Get current credits
    final requestsUsed = context.watch<RequestLimitService>().requestsUsed;
    final requestsLimit = context.watch<RequestLimitService>().requestsLimit;
    final remainingCredits = requestsLimit - requestsUsed;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Credits'), elevation: 0),
      body:
          isProcessing
              ? const ProcessingView()
              : CustomScrollView(
                slivers: [
                  // Header with current credits
                  CreditsHeader(remainingCredits: remainingCredits),

                  // Error messages
                  if (purchaseError != null)
                    StoreErrorCard(
                      message: 'Error: $purchaseError',
                      icon: Icons.error_outline,
                    ),

                  if (!storeAvailable)
                    const StoreErrorCard(
                      message:
                          'Store is currently unavailable. Please try again later.',
                      icon: Icons.store_mall_directory,
                    ),

                  // Section title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Choose a Credit Pack',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Credit packs grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final package = packages[index];
                        return CreditPackCard(
                          package: package,
                          onTap: () => _purchasePackage(package),
                        );
                      }, childCount: packages.length),
                    ),
                  ),

                  // Info section
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: InfoSection(),
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
    );
  }
}
