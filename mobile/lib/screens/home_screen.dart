import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/address_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _currentLocationAddressId = 'current-location-address';

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categorySectionKey = GlobalKey();
  final GlobalKey _orderAgainSectionKey = GlobalKey();

  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  final String _deliveryEta = '10 minutes';
  String _headerAddress = 'Fetching your location...';
  bool _resolvingLocation = true;
  int _activeBottomTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadHeaderAddress();
  }

  Future<void> _loadHeaderAddress() async {
    final auth = context.read<AuthProvider>();
    final fallback = _savedAddressLabel(auth.customer);

    setState(() {
      _headerAddress = fallback ?? 'Fetching your location...';
      _resolvingLocation = true;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _applyResolvedAddress(fallback);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _applyResolvedAddress(fallback);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final liveAddress = _placemarkLabel(placemark);
      final addressLine = [
        placemark?.name,
        placemark?.subLocality,
        placemark?.locality,
        placemark?.subAdministrativeArea,
      ]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      if (placemark != null && addressLine.isNotEmpty) {
        await auth.upsertSavedAddress({
          'id': _currentLocationAddressId,
          'label': 'Current',
          'name': (auth.customer?['name'] ?? '').toString().trim(),
          'phone': (auth.customer?['phone'] ?? '').toString().trim(),
          'address': addressLine.join(', '),
          'state': (placemark.administrativeArea ?? '').trim(),
          'pinCode': (placemark.postalCode ?? '').trim(),
        });
      }

      _applyResolvedAddress(liveAddress ?? fallback);
    } catch (_) {
      _applyResolvedAddress(fallback);
    }
  }

  void _applyResolvedAddress(String? value) {
    if (!mounted) return;
    setState(() {
      _headerAddress = value ?? 'Add delivery address';
      _resolvingLocation = false;
    });
  }

  String? _savedAddressLabel(Map<String, dynamic>? customer) {
    if (customer == null) return null;

    final address = (customer['address'] ?? '').toString().trim();
    final pinCode = (customer['pinCode'] ?? '').toString().trim();
    final state = (customer['state'] ?? '').toString().trim();
    final phone = (customer['phone'] ?? '').toString().trim();

    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);

    final localityParts = <String>[];
    if (pinCode.isNotEmpty) localityParts.add(pinCode);
    if (state.isNotEmpty) localityParts.add(state);
    if (localityParts.isNotEmpty) parts.add(localityParts.join(', '));
    if (phone.isNotEmpty) parts.add(phone);

    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  String? _placemarkLabel(Placemark? placemark) {
    if (placemark == null) return null;

    final primary =
      [placemark.name, placemark.subLocality, placemark.locality]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();

    final secondary =
      [placemark.postalCode, placemark.administrativeArea]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();

    if (primary.isEmpty && secondary.isEmpty) return null;
    final address = <String>[];
    if (primary.isNotEmpty) {
      address.add(primary.take(2).join(', '));
    }
    if (secondary.isNotEmpty) {
      address.add(secondary.join(', '));
    }
    return address.join(' • ');
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await ApiService.fetchProducts();
      final cats = products.map((p) => p.category).toSet().toList()..sort();
      setState(() {
        _products = products;
        _categories = ['All', ...cats];
        _applyFilterInternal();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() => setState(_applyFilterInternal);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilterInternal() {
    _filtered = _products.where((p) {
      final matchCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final grouped = <String, List<Product>>{};
    for (final p in _filtered) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }
    final sections = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3E8),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0C831F)),
            )
          : _error != null
          ? _buildError()
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(
                  child: Container(
                    key: _categorySectionKey,
                    child: _buildCategoryTabs(),
                  ),
                ),
                if (_filtered.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      key: _orderAgainSectionKey,
                      child: _ProductSection(
                        title: 'Frequently bought',
                        products: _filtered.take(10).toList(),
                      ),
                    ),
                  ),
                for (final s in sections)
                  SliverToBoxAdapter(
                    child: _ProductSection(title: s, products: grouped[s]!),
                  ),
                if (_filtered.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ),
      bottomNavigationBar: _buildBottomDock(cart),
    );
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _handleBottomTabTap(int index) async {
    setState(() => _activeBottomTab = index);

    if (index == 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (index == 1) {
      await _scrollToKey(_orderAgainSectionKey);
      return;
    }

    if (index == 2) {
      await _scrollToKey(_categorySectionKey);
      return;
    }

    if (!mounted) return;
    await Navigator.pushNamed(context, '/login');
    if (!mounted) return;
    setState(() => _activeBottomTab = 0);
  }

  Widget _buildHeader() {
    final auth = context.watch<AuthProvider>();
    final selectedAddress = auth.selectedAddress;
    final selectedAddressLabel = _savedAddressLabel(selectedAddress);
    final fallbackSavedAddress = _savedAddressLabel(auth.customer);
    final addressLabel = selectedAddressLabel ??
      (_resolvingLocation && fallbackSavedAddress != null
        ? fallbackSavedAddress
        : _headerAddress);
    final displayAddress = selectedAddress != null
      ? '${(selectedAddress['label'] ?? 'Home').toString().toUpperCase()} - ${selectedAddressLabel ?? ''}'
      : addressLabel == 'Fetching your location...' ||
          addressLabel == 'Add delivery address'
      ? addressLabel
      : 'HOME - $addressLabel';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFAC518), Color(0xFFF5A800)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Blinkit in',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _deliveryEta,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => showAddressPickerSheet(context),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 13,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  displayAddress,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _headerBtn(Icons.search, () {}),
                  const SizedBox(width: 8),
                  _headerBtn(
                    Icons.person_outline,
                    () => Navigator.pushNamed(context, '/login'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                onChanged: (v) {
                  _searchQuery = v;
                  _applyFilter();
                },
                decoration: InputDecoration(
                  hintText: 'Search for atta, dal, coke and more',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF888888),
                    size: 20,
                  ),
                  suffixIcon: const Icon(
                    Icons.mic_none,
                    color: Color(0xFF888888),
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    IconData iconForCat(String cat) {
      final lower = cat.toLowerCase();
      if (lower == 'all') return Icons.grid_view_rounded;
      if (lower.contains('summer')) return Icons.wb_sunny_outlined;
      if (lower.contains('elect')) return Icons.headphones_outlined;
      if (lower.contains('beauty')) {
        return Icons.face_retouching_natural_outlined;
      }
      if (lower.contains('deco') || lower.contains('house')) {
        return Icons.chair_outlined;
      }
      if (lower.contains('food') || lower.contains('grocery')) {
        return Icons.local_grocery_store_outlined;
      }
      if (lower.contains('health')) return Icons.favorite_outline;
      if (lower.contains('baby')) return Icons.child_friendly_outlined;
      return Icons.storefront_outlined;
    }

    return Container(
      color: const Color(0xFFF5F3E8),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      _applyFilter();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.black
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconForCat(cat),
                          size: 15,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadProducts, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBottomDock(CartProvider cart) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (cart.itemCount > 0) _buildCartBar(cart),
        _buildBottomNavBar(),
      ],
    );
  }

  Widget _buildCartBar(CartProvider cart) {
    final previewItems = cart.items.take(2).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/cart'),
          child: FractionallySizedBox(
            widthFactor: 0.68,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0C831F),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C831F).withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildCartPreview(previewItems),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'View cart',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '>',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: _bottomNavItem(
                  index: 0,
                  icon: Icons.home_filled,
                  label: 'Home',
                ),
              ),
              Expanded(
                child: _bottomNavItem(
                  index: 1,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Order Again',
                ),
              ),
              Expanded(
                child: _bottomNavItem(
                  index: 2,
                  icon: Icons.grid_view_rounded,
                  label: 'Categories',
                ),
              ),
              Expanded(
                child: _bottomNavItem(
                  index: 3,
                  icon: Icons.print_outlined,
                  label: 'Print',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _activeBottomTab == index;

    return InkWell(
      onTap: () => _handleBottomTabTap(index),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? Colors.black : const Color(0xFF555555),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.black : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPreview(List<CartItem> items) {
    if (items.isEmpty) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.shopping_basket_outlined,
          color: Color(0xFF0C831F),
          size: 18,
        ),
      );
    }

    return SizedBox(
      width: 34,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, child: _buildCartPreviewBubble(items.first)),
          if (items.length > 1)
            Positioned(left: 12, child: _buildCartPreviewBubble(items[1])),
        ],
      ),
    );
  }

  Widget _buildCartPreviewBubble(CartItem item) {
    final imageUrl = item.product.image;
    final hasImage = imageUrl != null && imageUrl.startsWith('http');

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => _buildCartPreviewFallback(item),
                errorWidget: (_, _, _) => _buildCartPreviewFallback(item),
              )
            : _buildCartPreviewFallback(item),
      ),
    );
  }

  Widget _buildCartPreviewFallback(CartItem item) {
    return Container(
      color: const Color(0xFFEAF7EC),
      alignment: Alignment.center,
      child: Text(
        item.product.name[0].toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF0C831F),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ─── Product Section ────────────────────────────────────────────────────────

class _ProductSection extends StatelessWidget {
  final String title;
  final List<Product> products;
  const _ProductSection({required this.title, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              padding: const EdgeInsets.only(right: 16),
              itemBuilder: (_, i) => _ProductCard(product: products[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Product Card ───────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  static const _bgColors = [
    Color(0xFFE8F5F0),
    Color(0xFFE8EEF8),
    Color(0xFFFFF5E8),
    Color(0xFFF8EBF5),
    Color(0xFFECF5E8),
    Color(0xFFE8F3F5),
    Color(0xFFFFF0F0),
    Color(0xFFF0F5FF),
  ];

  static const _letterColors = [
    Color(0xFF2E7D62),
    Color(0xFF2B5BA8),
    Color(0xFFB06E00),
    Color(0xFF7B3F96),
    Color(0xFF3A7B2E),
    Color(0xFF1A7A8A),
    Color(0xFFA03030),
    Color(0xFF303098),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.items.any((item) => item.product.id == product.id);
    final current = inCart
        ? cart.items.firstWhere((item) => item.product.id == product.id)
        : null;
    final mrp = (product.price * 1.25).round();
    final idx = product.name.codeUnitAt(0) % _bgColors.length;
    final hasImage = product.image != null && product.image!.startsWith('http');

    Widget imageWidget;
    if (hasImage) {
      imageWidget = CachedNetworkImage(
        imageUrl: product.image!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 126,
        placeholder: (context, url) => _letterFallback(idx),
        errorWidget: (context, url, err) => _letterFallback(idx),
      );
    } else {
      imageWidget = _letterFallback(idx);
    }

    return SizedBox(
      width: 152,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with ADD button overlay ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: imageWidget,
                ),
                // ADD / QTY button overlaid on bottom-right of image
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: inCart
                      ? Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C831F),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0C831F).withAlpha(90),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => context
                                    .read<CartProvider>()
                                    .decreaseQuantity(product.id),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 9,
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                '${current!.quantity}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context
                                    .read<CartProvider>()
                                    .addToCart(product),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 9,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () =>
                              context.read<CartProvider>().addToCart(product),
                          child: Container(
                            height: 36,
                            width: 74,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF0C831F),
                                width: 1.7,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'ADD',
                                style: TextStyle(
                                  color: Color(0xFF0C831F),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            // ── Info below image ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0C831F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '10 MINS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0C831F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (product.stock > 0 && product.stock <= 5)
                      Text(
                        'Only ${product.stock} left',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE05C2A),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'MRP ₹$mrp',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFAAAAAA),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _letterFallback(int idx) {
    return Container(
      width: double.infinity,
      height: 126,
      color: _bgColors[idx],
      child: Center(
        child: Text(
          product.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.w900,
            color: _letterColors[idx].withAlpha(46),
          ),
        ),
      ),
    );
  }
}
