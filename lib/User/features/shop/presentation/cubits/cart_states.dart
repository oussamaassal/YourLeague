import '../../domain/entities/cart_item.dart';

abstract class CartState {}

class CartInitial extends CartState {}

class CartUpdated extends CartState {
  final List<CartItem> items;
  CartUpdated(this.items);
}

class CartError extends CartState {
  final String message;
  CartError(this.message);
}

