class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? image;
  final String? description;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.image,
    this.description,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'General',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'],
      description: json['description'],
      stock: json['stock'] ?? 0,
    );
  }
}
