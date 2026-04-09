import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_rider_data.dart';
import '../models/rider_order.dart';
import '../providers/rider_auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    final rider = context.watch<RiderAuthProvider>().rider;
    final displayName = (rider?['name'] ?? riderName).toString();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(displayName),
                const SizedBox(height: 18),
                _buildOnlineCard(),
                const SizedBox(height: 18),
                _buildMetricsGrid(),
                const SizedBox(height: 18),
                _buildSectionTitle('Live orders', '2 active'),
                const SizedBox(height: 12),
                ...activeOrders.map(_buildOrderCard),
                const SizedBox(height: 18),
                _buildSectionTitle('Hot zones', 'Best earning areas'),
                const SizedBox(height: 12),
                ...topZones.map(_buildZoneCard),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String displayName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blinkit Rider',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hello, $displayName',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }

  Widget _buildOnlineCard() {
    final bg = _isOnline ? const Color(0xFF0E8A39) : const Color(0xFF2F3136);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFFB2F5C0) : const Color(0xFF9CA3AF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isOnline ? 'You are online' : 'You are offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Stay close to busy zones to receive faster delivery assignments and incentive boosts.',
            style: TextStyle(
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: bg,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: () {
              setState(() => _isOnline = !_isOnline);
            },
            child: Text(_isOnline ? 'Go offline' : 'Go online'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: todayMetrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 110,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final metric = todayMetrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        Text(
          action,
          style: const TextStyle(
            color: Color(0xFF0E8A39),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(RiderOrder order) {
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
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.priority,
                      style: const TextStyle(
                        color: Color(0xFF0E8A39),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.customerName} • ${order.area}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _pill('${order.items} items'),
                  const SizedBox(width: 8),
                  _pill('${order.distanceKm.toStringAsFixed(1)} km'),
                  const SizedBox(width: 8),
                  _pill(order.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Rs ${order.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.pickupEtaMin + order.dropEtaMin} min total',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF667085),
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

  Widget _buildZoneCard(RiderZone zone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          title: Text(
            zone.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text('${zone.load} load • ${zone.incentive}'),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}