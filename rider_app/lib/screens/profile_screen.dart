import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_rider_data.dart';
import '../providers/rider_auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<RiderAuthProvider>();
    final rider = auth.rider ?? const <String, dynamic>{};
    final displayName = (rider['name'] ?? riderName).toString();
    final phone = (rider['phone'] ?? '').toString();
    final riderId = (rider['_id'] ?? 'Pending').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text(
          'Profile',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F7EA),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF0E8A39),
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 4),
                      Text(
                        phone.isEmpty ? 'Rider ID: $riderId' : '$phone • Rider ID: $riderId',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _MenuTile(
          icon: Icons.badge_outlined,
          title: 'Documents',
          subtitle: 'License, RC, insurance and ID proofs',
        ),
        const SizedBox(height: 12),
        const _MenuTile(
          icon: Icons.two_wheeler_outlined,
          title: 'Vehicle details',
          subtitle: 'Update bike and fuel information',
        ),
        const SizedBox(height: 12),
        const _MenuTile(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          subtitle: 'Call hub manager or raise delivery issues',
        ),
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'Sign out from this rider device',
          onTap: () async {
            await context.read<RiderAuthProvider>().logout();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          },
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(icon, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}