import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

  void _applyFilterInternal() {
    _filtered = _products.where((p) {
      final matchCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
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
              child: CircularProgressIndicator(color: Color(0xFF0C831F)))
          : _error != null
              ? _buildError()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildCategoryTabs()),
                    if (_filtered.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _ProductSection(
                          title: 'Frequently bought',
                          products: _filtered.take(10).toList(),
                        ),
                      ),
                    for (final s in sections)
                      SliverToBoxAdapter(
                        child: _ProductSection(
                            title: s, products: grouped[s]!),
                      ),
                    if (_filtered.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text('No products found',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
      bottomNavigationBar:
          cart.itemCount > 0 ? _buildCartBar(cart) : null,
    );
  }

  Widget _buildHeader() {
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
                      children: const [
                        Text('Blinkit in',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                        Text('10 minutes',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                height: 1.1)),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 13, color: Colors.black87),
                            SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                'HOME - Parveen jakhar, Gali...',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down,
                                size: 16, color: Colors.black87),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _headerBtn(Icons.search, () {}),
                  const SizedBox(width: 8),
                  _headerBtn(Icons.person_outline,
                      () => Navigator.pushNamed(context, '/login')),
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
                      fontSize: 14, color: Color(0xFF888888)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF888888), size: 20),
                  suffixIcon: const Icon(Icons.mic_none,
                      color: Color(0xFF888888), size: 20),
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
      if (lower.contains('beauty')) return Icons.face_retouching_natural_outlined;
      if (lower.contains('deco') || lower.contains('house')) return Icons.chair_outlined;
      if (lower.contains('food') || lower.contains('grocery')) return Icons.local_grocery_store_outlined;
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
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? Colors.black : const Color(0xFFCCCCCC),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconForCat(cat),
                            size: 15,
                            color: selected ? Colors.white : Colors.black87),
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
          Text(_error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadProducts, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildCartBar(CartProvider cart) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/cart'),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF0C831F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.itemCount} item${cart.itemCount > 1 ? "s" : ""}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      const Text('View cart',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  '₹${cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
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
          Text(title,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.black)),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
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
    final hasImage =
        product.image != null && product.image!.startsWith('http');

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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
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
                                color:
                                    const Color(0xFF0C831F).withAlpha(90),
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
                                    horizontal: 10, vertical: 9),
                                  child: Icon(Icons.remove,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                              Text('${current!.quantity}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14)),
                              GestureDetector(
                                onTap: () => context
                                    .read<CartProvider>()
                                    .addToCart(product),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 9),
                                  child: Icon(Icons.add,
                                      size: 14, color: Colors.white),
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
                                  color: const Color(0xFF0C831F), width: 1.7),
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
                        const Text('10 MINS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0C831F))),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (product.stock > 0 && product.stock <= 5)
                      Text(
                        'Only ${product.stock} left',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE05C2A)),
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
                            height: 1.25),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 5),
                        Text('MRP ₹$mrp',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFAAAAAA),
                                decoration: TextDecoration.lineThrough)),
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
