import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_rider_data.dart';
import '../providers/rider_orders_provider.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderOrdersProvider>().fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiderOrdersProvider>();
    final earnings = provider.earnings;
    final bars = earnings?.weeklyBars ?? weeklyBars;
    final metrics = earnings == null
        ? earningsMetrics
        : [
            RiderMetric('Today', 'Rs ${earnings.today.toStringAsFixed(0)}'),
            RiderMetric('This Week', 'Rs ${earnings.week.toStringAsFixed(0)}'),
            RiderMetric('Incentives', 'Rs ${earnings.incentives.toStringAsFixed(0)}'),
            RiderMetric('Wallet Balance', 'Rs ${earnings.walletBalance.toStringAsFixed(0)}'),
          ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text(
          'Earnings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This week payout',
                style: TextStyle(color: Color(0xFFCBD5E1)),
              ),
              const SizedBox(height: 10),
              Text(
                'Rs ${(earnings?.week ?? 8940).toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                earnings?.nextSettlement.isNotEmpty == true
                    ? 'Next settlement: ${earnings!.nextSettlement}'
                    : 'Next settlement: Friday, 6:00 PM',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars
                    .map(
                      (value) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 120 * value,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34D399),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 108,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      metric.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}