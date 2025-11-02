import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/cart_item.dart';
import '../../data/email_service.dart';
import 'cart_states.dart';

class CartCubit extends Cubit<CartState> {
  final List<CartItem> _items = [];
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  CartCubit() : super(CartInitial());

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.total);

  void addItem(CartItem item) async {
    final existingItemIndex = _items.indexWhere((i) => i.productId == item.productId);

    if (existingItemIndex != -1) {
      _items[existingItemIndex] = _items[existingItemIndex].copyWith(
        quantity: _items[existingItemIndex].quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }

    emit(CartUpdated(_items));

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser?.email != null) {
      EmailService.sendCartConfirmation(
        userEmail: currentUser!.email!,
        productName: item.name,
        productPrice: item.price,
        quantity: item.quantity,
      );
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    emit(CartUpdated(_items));
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      emit(CartUpdated(_items));
    }
  }

  void clearCart() {
    _items.clear();
    emit(CartUpdated(_items));
  }

  void loadCart(List<CartItem> items) {
    _items.clear();
    _items.addAll(items);
    emit(CartUpdated(_items));
  }
}

