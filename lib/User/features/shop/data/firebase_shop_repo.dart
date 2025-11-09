import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/product.dart';
import '../domain/entities/order.dart';
import '../domain/entities/transaction.dart';
    
import '../domain/entities/review.dart';
    
    
import '../domain/repos/shop_repo.dart';

class FirebaseShopRepo implements ShopRepo {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //         ====== PRODUCT CRUD         ======

  @override
  Future<void> createProduct(Product product) async {
    try {
      await _firestore.collection('products').doc(product.id).set(product.toJson());
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  @override
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()!))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()!))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      await _firestore.collection('products').doc(product.id).update(product.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  //         ====== ORDER CRUD         ======

  @override
  Future<void> createOrder(Order order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toJson());
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Future<Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return Order.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  @override
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Order.fromJson(doc.data()!))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  @override
  Future<List<Order>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Order.fromJson(doc.data()!))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  @override
  Future<void> updateOrder(Order order) async {
    try {
      await _firestore.collection('orders').doc(order.id).update(order.toJson());
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  //         ====== TRANSACTION CRUD         ======

  @override
  Future<void> createTransaction(Transaction transaction) async {
    try {
      await _firestore.collection('transactions').doc(transaction.id).set(transaction.toJson());
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      final doc = await _firestore.collection('transactions').doc(transactionId).get();
      if (doc.exists) {
        return Transaction.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  @override
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Transaction.fromJson(doc.data()!))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user transactions: $e');
    }
  }

  @override
  Future<List<Transaction>> getOrderTransactions(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Transaction.fromJson(doc.data()!))
          .toList();
    } catch (e) {
      throw Exception('Failed to get order transactions: $e');
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _firestore.collection('transactions').doc(transaction.id).update(transaction.toJson());
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }
    

  //         ====== REVIEW CRUD         ======

  @override
  Future<void> createReview(Review review) async {
    try {
      await _firestore
          .collection('products')
          .doc(review.productId)
          .collection('reviews')
          .doc(review.id)
          .set(review.toJson());
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  @override
  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Review.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get product reviews: $e');
    }
  }

  @override
  Future<Review?> getUserReviewForProduct(String productId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return Review.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get user review: $e');
    }
  }

  @override
  Future<void> updateReview(Review review) async {
    try {
      await _firestore
          .collection('products')
          .doc(review.productId)
          .collection('reviews')
          .doc(review.id)
          .update(review.toJson());
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  @override
  Future<void> deleteReview(String productId, String reviewId) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(reviewId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
    
    
}

