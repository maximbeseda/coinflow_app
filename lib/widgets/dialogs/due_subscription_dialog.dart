import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_model.dart';
import '../../providers/finance_provider.dart';

class DueSubscriptionDialog extends StatelessWidget {
  final Subscription subscription;

  const DueSubscriptionDialog({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Регулярний платіж 💸',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                    children: [
                      const TextSpan(text: 'Настав час оплатити підписку\n'),
                      TextSpan(
                        text: subscription.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${subscription.amount} ₴',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.black87,
                        ),
                        onPressed: () async {
                          await context
                              .read<FinanceProvider>()
                              .skipSubscriptionPayment(subscription);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          "Пропустити",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          // Зберігаємо посилання на ScaffoldMessenger до async-паузи
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);

                          final (success, message) = await context
                              .read<FinanceProvider>()
                              .confirmSubscriptionPayment(
                                subscription,
                                subscription.amount,
                              );

                          if (success) {
                            navigator.pop();
                          }

                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.white,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(
                                bottom: 30,
                                left: 20,
                                right: 20,
                              ),
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: success
                                      ? Colors.green.withValues(alpha: 0.5)
                                      : Colors.red.withValues(alpha: 0.5),
                                ),
                              ),
                              content: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: success
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      success
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      color: success
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Сплатити",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Хрестик закриття ---
          Positioned(
            right: 16,
            top: 16,
            child: GestureDetector(
              onTap: () {
                context.read<FinanceProvider>().ignoreSubscriptionForSession(
                  subscription.id,
                );
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.black87, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
