import '../../domain/entities/product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/transaction.dart';

abstract class ShopState {}

class ShopInitial extends ShopState {}

class ShopLoading extends ShopState {}

class ProductLoaded extends ShopState {
  final Product product;
  ProductLoaded(this.product);
}

class ProductsLoaded extends ShopState {
  final List<Product> products;
  ProductsLoaded(this.products);
}

class OrderLoaded extends ShopState {
  final Order order;
  OrderLoaded(this.order);
}

class OrdersLoaded extends ShopState {
  final List<Order> orders;
  OrdersLoaded(this.orders);
}

class TransactionLoaded extends ShopState {
  final Transaction transaction;
  TransactionLoaded(this.transaction);
}

class TransactionsLoaded extends ShopState {
  final List<Transaction> transactions;
  TransactionsLoaded(this.transactions);
}

class OperationSuccess extends ShopState {
  final String message;
  OperationSuccess(this.message);
}

class ShopError extends ShopState {
  final String message;
  ShopError(this.message);
}

