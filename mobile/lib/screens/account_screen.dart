import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/address_bottom_sheet.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _hideSensitiveItems = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final customer = auth.customer ?? const <String, dynamic>{};
    final name = (customer['name'] ?? '').toString().trim();
    final phone = (customer['phone'] ?? '').toString().trim();
    final address = (customer['address'] ?? '').toString().trim();
    final state = (customer['state'] ?? '').toString().trim();
    final pinCode = (customer['pinCode'] ?? '').toString().trim();
    final fullAddress = [address, state, pinCode]
        .where((value) => value.trim().isNotEmpty)
        .join(', ');
    final displayName = name.isEmpty ? 'Your account' : name;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8D96A), Color(0xFFF3F4F8), Color(0xFFF3F4F8)],
            stops: [0.0, 0.28, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _circleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 18),
                const CircleAvatar(
                  radius: 76,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 74,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF232323),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF646B73),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Your orders',
                        onTap: () => _showInfo(context, 'Order history is linked to your verified account.'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _actionCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Blinkit\nMoney',
                        onTap: () => _showInfo(context, 'Wallet features can be added here next.'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _actionCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Need help?',
                        onTap: () => _showInfo(context, 'Support options can be connected here.'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _settingTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Appearance',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LIGHT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6D7380),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF8A8F99),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F8EF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.visibility_off_outlined,
                          color: Color(0xFF4C9E42),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hide sensitive items',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF242424),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sexual wellness, nicotine products and other sensitive items will be hidden.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: Color(0xFF6A7078),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Switch.adaptive(
                        value: _hideSensitiveItems,
                        activeThumbColor: const Color(0xFF0C831F),
                        activeTrackColor: const Color(0xFF9DD7A6),
                        onChanged: (value) {
                          setState(() => _hideSensitiveItems = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
                        child: Text(
                          'Your information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF232323),
                          ),
                        ),
                      ),
                      _infoTile(
                        icon: Icons.map_outlined,
                        title: 'Address book',
                        subtitle: auth.savedAddresses.isEmpty
                            ? 'Add delivery address'
                            : '${auth.savedAddresses.length} saved address${auth.savedAddresses.length == 1 ? '' : 'es'}',
                        onTap: () => showAddressPickerSheet(context),
                      ),
                      _infoTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile details',
                        subtitle: fullAddress.isEmpty
                            ? 'Verified phone and account details'
                            : fullAddress,
                        onTap: () => _showProfileSheet(context, customer),
                      ),
                      _infoTile(
                        icon: Icons.favorite_border_rounded,
                        title: 'Your wishlist',
                        subtitle: 'Saved items coming soon',
                        onTap: () => _showInfo(context, 'Wishlist can be connected next.'),
                      ),
                      _infoTile(
                        icon: Icons.description_outlined,
                        title: 'GST details',
                        subtitle: 'Add tax details for invoices',
                        onTap: () => _showInfo(context, 'GST setup can be added here.'),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: const Color(0xFF232323), size: 24),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 134,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34, color: const Color(0xFF222222)),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF232323),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF292929), size: 27),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF232323),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          leading: Icon(icon, color: const Color(0xFF2A2A2A), size: 28),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF232323),
            ),
          ),
          subtitle: subtitle.trim().isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7B8188),
                    ),
                  ),
                ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFB0B5BE),
            size: 28,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, indent: 18, endIndent: 18),
      ],
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showProfileSheet(
    BuildContext context,
    Map<String, dynamic> customer,
  ) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Name', (customer['name'] ?? '').toString().trim()),
      MapEntry('Phone', (customer['phone'] ?? '').toString().trim()),
      MapEntry('Address', (customer['address'] ?? '').toString().trim()),
      MapEntry('State', (customer['state'] ?? '').toString().trim()),
      MapEntry('PIN code', (customer['pinCode'] ?? '').toString().trim()),
    ].where((entry) => entry.value.isNotEmpty).toList();

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verified account details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                ...rows.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7A808A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF232323),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}