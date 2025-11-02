import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final int stockQuantity;
  final String category;
  final bool isAvailable;
  final fs.Timestamp createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.stockQuantity,
    required this.category,
    required this.isAvailable,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'stockQuantity': stockQuantity,
      'category': category,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      stockQuantity: json['stockQuantity'],
      category: json['category'],
      isAvailable: json['isAvailable'],
      createdAt: json['createdAt'],
    );
  }
}

