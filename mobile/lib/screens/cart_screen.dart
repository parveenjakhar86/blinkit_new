import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/address_bottom_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCodeCtrl = TextEditingController();
  String _paymentMethod = 'upi';
  bool _placing = false;
  bool _redirectingToHome = false;
  bool _orderPlaced = false;

  void _refreshFooter() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_refreshFooter);
    _phoneCtrl.addListener(_refreshFooter);
    _addressCtrl.addListener(_refreshFooter);
    _stateCtrl.addListener(_refreshFooter);
    _pinCodeCtrl.addListener(_refreshFooter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedDeliveryDetails();
    });
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_refreshFooter);
    _phoneCtrl.removeListener(_refreshFooter);
    _addressCtrl.removeListener(_refreshFooter);
    _stateCtrl.removeListener(_refreshFooter);
    _pinCodeCtrl.removeListener(_refreshFooter);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _stateCtrl.dispose();
    _pinCodeCtrl.dispose();
    super.dispose();
  }

  void _loadSavedDeliveryDetails() {
    final auth = context.read<AuthProvider>();
    final customer = auth.selectedAddress ?? auth.customer;
    if (customer == null) return;

    _nameCtrl.text = customer['name'] ?? '';
    _phoneCtrl.text = customer['phone'] ?? '';
    _addressCtrl.text = customer['address'] ?? '';
    _stateCtrl.text = customer['state'] ?? '';
    _pinCodeCtrl.text = customer['pinCode']?.toString() ?? '';
  }

  Future<void> _showAddressSheet() async {
    await showAddressPickerSheet(context);
    _loadSavedDeliveryDetails();
    if (mounted) setState(() {});
  }

  Future<void> _placeOrder() async {
    if (!_hasSavedDeliveryDetails) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a delivery address before placing the order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    setState(() => _placing = true);
    try {
      final result = await ApiService.placeOrder(
        customerDetails: {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'pinCode': _pinCodeCtrl.text.trim(),
        },
        products: cart.items
            .map(
              (i) => {
                'product': i.product.id,
                'name': i.product.name,
                'price': i.product.price,
                'quantity': i.quantity,
              },
            )
            .toList(),
        paymentMethod: _paymentMethod,
        totalAmount: cart.total,
        authToken: auth.token,
      );
      await auth.updateCustomerProfile({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pinCode': _pinCodeCtrl.text.trim(),
      });
      _orderPlaced = true;
      cart.clearCart();
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/order-success',
          arguments: result,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _selectPaymentMethod(String method) {
    if (!mounted) return;
    setState(() => _paymentMethod = method);
  }

  Future<void> _showPaymentOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose payment method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _paymentSheetTile(
                  value: 'upi',
                  title: 'PhonePe UPI',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _paymentSheetTile(
                  value: 'credit_card',
                  title: 'Credit Card',
                  icon: Icons.credit_card_outlined,
                ),
                _paymentSheetTile(
                  value: 'cod',
                  title: 'Cash on Delivery',
                  icon: Icons.local_atm_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty && !_redirectingToHome && !_orderPlaced) {
      _redirectingToHome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 180),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.timelapse_rounded,
                            color: Color(0xFF5F7C4A),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Free delivery in 9 minutes',
                            style: TextStyle(
                              fontSize: 26 / 1.4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Shipment of ${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
                        style: const TextStyle(color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 10),
                      ...cart.items.map((item) => _cartItemTile(item)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _deliveryCard(),
                const SizedBox(height: 12),
                _paymentCard(),
              ],
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD54F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              color: Color(0xFF222222),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivering to Home',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                ),
                                Text(
                                  _fullAddress.isEmpty
                                      ? 'Add your delivery address'
                                      : _fullAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF606060),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _showAddressSheet,
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 11,
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: _showPaymentOptions,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE8E8E8),
                                      ),
                                    ),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 62,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          _paymentLeading(),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'PAY USING',
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    height: 1,
                                                    color: Color(0xFF6A6A6A),
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  _paymentFooterLabel(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    height: 1,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF525252),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 15,
                              child: ElevatedButton(
                                onPressed: _placing ? null : _placeOrder,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(62),
                                  backgroundColor: const Color(0xFF0C831F),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: _placing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '₹${cart.total.toStringAsFixed(0)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const Text(
                                                'TOTAL',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  height: 1,
                                                  letterSpacing: 0.3,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Place Order',
                                              maxLines: 1,
                                              overflow: TextOverflow.visible,
                                              softWrap: false,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.play_arrow_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _cartItemTile(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child:
                  item.product.image != null &&
                      item.product.image!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: item.product.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ColoredBox(color: Color(0xFFE8EFF2)),
                      errorWidget: (context, url, error) =>
                          const _CartImageFallback(),
                    )
                  : const _CartImageFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17 / 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${item.product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 24 / 1.4,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C831F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _qtyBtn(
                  Icons.remove,
                  () => context.read<CartProvider>().decreaseQuantity(
                    item.product.id,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _qtyBtn(
                  Icons.add,
                  () => context.read<CartProvider>().addToCart(item.product),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryCard() {
    final selectedAddress = context.watch<AuthProvider>().selectedAddress;
    final addressLabel =
        (selectedAddress?['label'] ?? 'Home').toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _hasSavedDeliveryDetails
                ? 'Delivering to $addressLabel'
                : 'Add Delivery Address',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (_hasSavedDeliveryDetails) ...[
            Text(
              _nameCtrl.text.trim(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              _phoneCtrl.text.trim(),
              style: const TextStyle(color: Color(0xFF606060)),
            ),
            const SizedBox(height: 4),
            Text(
              _fullAddress,
              style: const TextStyle(color: Color(0xFF606060), height: 1.4),
            ),
          ] else
            const Text(
              'Choose a saved address or add a new one from the address popup.',
              style: TextStyle(color: Color(0xFF606060), height: 1.4),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _showAddressSheet,
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: Text(
                _hasSavedDeliveryDetails
                    ? 'Change / Add another address'
                    : 'Add address',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _paymentTile(
            'upi',
            'PhonePe UPI',
            Icons.account_balance_wallet_outlined,
          ),
          _paymentTile(
            'credit_card',
            'Credit Card',
            Icons.credit_card_outlined,
          ),
          _paymentTile('cod', 'Cash on Delivery', Icons.local_atm_outlined),
        ],
      ),
    );
  }

  Widget _paymentTile(String value, String title, IconData icon) {
    return GestureDetector(
      onTap: () => _selectPaymentMethod(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _paymentMethod == value
              ? const Color(0xFFEFF9EF)
              : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _paymentMethod == value
                ? const Color(0xFF0C831F)
                : const Color(0xFFE6E6E6),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Icon(icon, color: const Color(0xFF0C831F), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(
              _paymentMethod == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: const Color(0xFF0C831F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentSheetTile({
    required String value,
    required String title,
    required IconData icon,
  }) {
    final selected = _paymentMethod == value;

    return InkWell(
      onTap: () {
        _selectPaymentMethod(value);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF9EF) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0C831F) : const Color(0xFFE6E6E6),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0C831F), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off_rounded,
              color: const Color(0xFF0C831F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  String _paymentFooterLabel() {
    if (_paymentMethod == 'upi') return 'UPI';
    if (_paymentMethod == 'credit_card') return 'Card';
    return 'COD';
  }

  String get _fullAddress {
    final parts = [
      _addressCtrl.text.trim(),
      _stateCtrl.text.trim(),
      _pinCodeCtrl.text.trim(),
    ].where((value) => value.isNotEmpty);

    return parts.join(', ');
  }

  bool get _hasSavedDeliveryDetails {
    return _nameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _addressCtrl.text.trim().isNotEmpty &&
        _stateCtrl.text.trim().isNotEmpty &&
        _pinCodeCtrl.text.trim().isNotEmpty;
  }

  Widget _paymentLeading() {
    if (_paymentMethod == 'upi') {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF5F2EEA),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.currency_rupee_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    }

    if (_paymentMethod == 'credit_card') {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF1550B3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.credit_card_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.payments_rounded, size: 14, color: Colors.white),
    );
  }
}

class _CartImageFallback extends StatelessWidget {
  const _CartImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE8EFF2),
      child: Center(
        child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF0C831F)),
      ),
    );
  }
}
