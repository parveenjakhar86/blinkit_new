import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rider_order.dart';
import '../providers/rider_orders_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderOrdersProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiderOrdersProvider>();
    final active = provider.activeOrders;
    final available = provider.availableOrders;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text(
          'Orders Queue',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Track active deliveries and pick the next nearby order.',
          style: TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        const _QueueBanner(),
        const SizedBox(height: 18),
        const Text(
          'Active now',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (provider.loadingOrders)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (active.isEmpty)
          const _EmptyCard(label: 'No active deliveries yet.')
        else
          ...active.map((order) => _OrderTile(order: order, emphasize: true)),
        const SizedBox(height: 18),
        const Text(
          'Available nearby',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (!provider.loadingOrders && available.isEmpty)
          const _EmptyCard(label: 'No nearby orders are available right now.')
        else
          ...available.map((order) => _OrderTile(order: order)),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _QueueBanner extends StatelessWidget {
  const _QueueBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E8A39), Color(0xFF1FA851)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Accept 3 more orders in the next hour to unlock your peak bonus.',
              style: TextStyle(
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, this.emphasize = false});

  final RiderOrder order;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RiderOrdersProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Text(
                    'Rs ${order.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: emphasize ? const Color(0xFF0E8A39) : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.customerName} • ${order.area}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _InfoBlock(label: 'Pickup', value: '${order.pickupEtaMin} min')),
                  Expanded(child: _InfoBlock(label: 'Drop', value: '${order.dropEtaMin} min')),
                  Expanded(child: _InfoBlock(label: 'Distance', value: '${order.distanceKm.toStringAsFixed(1)} km')),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(order.area)),
                        );
                      },
                      child: const Text('View route'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        if (emphasize) {
                          final nextStatus = order.status == 'accepted' ? 'picked_up' : 'delivered';
                          await provider.updateOrderStatus(order.id, nextStatus);
                        } else {
                          await provider.acceptOrder(order.id);
                        }
                      },
                      child: Text(
                        emphasize
                            ? (order.status == 'accepted' ? 'Mark picked up' : 'Mark delivered')
                            : 'Accept order',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}