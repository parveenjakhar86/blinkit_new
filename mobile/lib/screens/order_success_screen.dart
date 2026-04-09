import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  String _deliveryEtaText(String orderId) {
    final seed = orderId.runes.fold<int>(0, (sum, rune) => sum + rune);
    final eta = 10 + (seed % 6);
    return '$eta minutes';
  }

  @override
  Widget build(BuildContext context) {
    final order =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final orderId = order?['_id'] ?? order?['order']?['_id'] ?? '—';
    final etaText = _deliveryEtaText(orderId.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE9F7EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 58,
                        color: Color(0xFF0C831F),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Order placed successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5F6368),
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Delivery expected in '),
                          TextSpan(
                            text: etaText,
                            style: const TextStyle(
                              color: Color(0xFF0C831F),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Order ID: $orderId',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B1B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (_) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C831F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Continue Shopping',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
