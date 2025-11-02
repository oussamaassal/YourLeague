import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/review.dart';
import '../../domain/repos/shop_repo.dart';
import 'shop_states.dart';

class ShopCubit extends Cubit<ShopState> {
  final ShopRepo shopRepo;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  ShopCubit({required this.shopRepo}) : super(ShopInitial());

  // ==================== PRODUCT CRUD ====================

  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    String? imageUrl,
    required int stockQuantity,
    required String category,
    bool isAvailable = true,
  }) async {
    try {
      emit(ShopLoading());
      
      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        stockQuantity: stockQuantity,
        category: category,
        isAvailable: isAvailable,
        createdAt: fs.Timestamp.now(),
      );

      await shopRepo.createProduct(product);
      
      // Reload products after successful creation
      final products = await shopRepo.getAllProducts();
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ShopError('Failed to create product: $e'));
    }
  }

  Future<void> getProduct(String productId) async {
    try {
      emit(ShopLoading());
      final product = await shopRepo.getProduct(productId);
      if (product != null) {
        emit(ProductLoaded(product));
      } else {
        emit(ShopError('Product not found'));
      }
    } catch (e) {
      emit(ShopError('Failed to get product: $e'));
    }
  }

  Future<void> getAllProducts() async {
    try {
      emit(ShopLoading());
      final products = await shopRepo.getAllProducts();
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ShopError('Failed to get products: $e'));
    }
  }

  Future<void> getProductsByCategory(String category) async {
    try {
      emit(ShopLoading());
      final products = await shopRepo.getProductsByCategory(category);
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ShopError('Failed to get products by category: $e'));
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      emit(ShopLoading());
      await shopRepo.updateProduct(product);
      
      // Reload products after successful update
      final products = await shopRepo.getAllProducts();
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ShopError('Failed to update product: $e'));
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      emit(ShopLoading());
      await shopRepo.deleteProduct(productId);
      
      // Reload products after successful deletion
      final products = await shopRepo.getAllProducts();
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ShopError('Failed to delete product: $e'));
    }
  }

  // ==================== ORDER CRUD ====================

  Future<void> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required String shippingAddress,
  }) async {
    try {
      emit(ShopLoading());

      final totalAmount = items.fold<double>(
        0.0,
        (sum, item) => sum + (item['price'] * item['quantity']),
      );

      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        items: items,
        totalAmount: totalAmount,
        status: 'pending',
        shippingAddress: shippingAddress,
        createdAt: fs.Timestamp.now(),
      );

      await shopRepo.createOrder(order);
      emit(OperationSuccess('Order created successfully'));
    } catch (e) {
      emit(ShopError('Failed to create order: $e'));
    }
  }

  Future<void> getOrder(String orderId) async {
    try {
      emit(ShopLoading());
      final order = await shopRepo.getOrder(orderId);
      if (order != null) {
        emit(OrderLoaded(order));
      } else {
        emit(ShopError('Order not found'));
      }
    } catch (e) {
      emit(ShopError('Failed to get order: $e'));
    }
  }

  Future<void> getUserOrders(String userId) async {
    try {
      emit(ShopLoading());
      final orders = await shopRepo.getUserOrders(userId);
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(ShopError('Failed to get user orders: $e'));
    }
  }

  Future<void> getAllOrders() async {
    try {
      emit(ShopLoading());
      final orders = await shopRepo.getAllOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(ShopError('Failed to get orders: $e'));
    }
  }

  Future<void> updateOrder(Order order) async {
    try {
      emit(ShopLoading());
      await shopRepo.updateOrder(order);
      emit(OperationSuccess('Order updated successfully'));
    } catch (e) {
      emit(ShopError('Failed to update order: $e'));
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      emit(ShopLoading());
      await shopRepo.deleteOrder(orderId);
      emit(OperationSuccess('Order deleted successfully'));
    } catch (e) {
      emit(ShopError('Failed to delete order: $e'));
    }
  }

  // ==================== TRANSACTION CRUD ====================

  Future<void> createTransaction({
    required String userId,
    required String orderId,
    required String type,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      emit(ShopLoading());

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        orderId: orderId,
        type: type,
        amount: amount,
        paymentMethod: paymentMethod,
        status: 'pending',
        createdAt: fs.Timestamp.now(),
        transactionId: transactionId,
      );

      await shopRepo.createTransaction(transaction);
      emit(OperationSuccess('Transaction created successfully'));
    } catch (e) {
      emit(ShopError('Failed to create transaction: $e'));
    }
  }

  Future<void> getTransaction(String transactionId) async {
    try {
      emit(ShopLoading());
      final transaction = await shopRepo.getTransaction(transactionId);
      if (transaction != null) {
        emit(TransactionLoaded(transaction));
      } else {
        emit(ShopError('Transaction not found'));
      }
    } catch (e) {
      emit(ShopError('Failed to get transaction: $e'));
    }
  }

  Future<void> getUserTransactions(String userId) async {
    try {
      emit(ShopLoading());
      final transactions = await shopRepo.getUserTransactions(userId);
      emit(TransactionsLoaded(transactions));
    } catch (e) {
      emit(ShopError('Failed to get user transactions: $e'));
    }
  }

  Future<void> getOrderTransactions(String orderId) async {
    try {
      emit(ShopLoading());
      final transactions = await shopRepo.getOrderTransactions(orderId);
      emit(TransactionsLoaded(transactions));
    } catch (e) {
      emit(ShopError('Failed to get order transactions: $e'));
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      emit(ShopLoading());
      await shopRepo.updateTransaction(transaction);
      emit(OperationSuccess('Transaction updated successfully'));
    } catch (e) {
      emit(ShopError('Failed to update transaction: $e'));
    }
  }

  // ==================== REVIEW CRUD ====================

  Future<void> createReview({
    required String productId,
    required int rating,
    required String comment,
    String? userName,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(ShopError('You must be logged in to leave a review'));
        return;
      }

      emit(ShopLoading());

      // Check if user already has a review for this product
      final existingReview = await shopRepo.getUserReviewForProduct(productId, currentUser.uid);
      
      final reviewId = existingReview?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final review = Review(
        id: reviewId,
        productId: productId,
        userId: currentUser.uid,
        userName: userName ?? currentUser.email?.split('@').first ?? 'Anonymous',
        rating: rating,
        comment: comment,
        createdAt: fs.Timestamp.now(),
      );

      if (existingReview != null) {
        await shopRepo.updateReview(review);
      } else {
        await shopRepo.createReview(review);
      }

      // Reload reviews after creating/updating
      final reviews = await shopRepo.getProductReviews(productId);
      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ShopError('Failed to create review: $e'));
    }
  }

  Future<void> getProductReviews(String productId) async {
    try {
      emit(ShopLoading());
      final reviews = await shopRepo.getProductReviews(productId);
      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ShopError('Failed to get reviews: $e'));
    }
  }

  Future<void> deleteReview(String productId, String reviewId) async {
    try {
      emit(ShopLoading());
      await shopRepo.deleteReview(productId, reviewId);
      
      // Reload reviews after deletion
      final reviews = await shopRepo.getProductReviews(productId);
      emit(ReviewsLoaded(reviews));
    } catch (e) {
      emit(ShopError('Failed to delete review: $e'));
    }
  }
}

