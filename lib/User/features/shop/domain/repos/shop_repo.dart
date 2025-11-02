import '../entities/product.dart';
import '../entities/order.dart';
import '../entities/transaction.dart';

abstract class ShopRepo {
  // Product CRUD
  Future<void> createProduct(Product product);
  Future<Product?> getProduct(String productId);
  Future<List<Product>> getAllProducts();
  Future<List<Product>> getProductsByCategory(String category);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String productId);

  // Order CRUD
  Future<void> createOrder(Order order);
  Future<Order?> getOrder(String orderId);
  Future<List<Order>> getUserOrders(String userId);
  Future<List<Order>> getAllOrders();
  Future<void> updateOrder(Order order);
  Future<void> deleteOrder(String orderId);

  // Transaction CRUD
  Future<void> createTransaction(Transaction transaction);
  Future<Transaction?> getTransaction(String transactionId);
  Future<List<Transaction>> getUserTransactions(String userId);
  Future<List<Transaction>> getOrderTransactions(String orderId);
  Future<void> updateTransaction(Transaction transaction);
}

