import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cubits/cart_cubit.dart';
import '../cubits/cart_states.dart';
import '../cubits/shop_cubit.dart';
import '../../domain/entities/order.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartInitial) {
            return const Center(child: Text('Cart is empty'));
          }

          if (state is CartUpdated) {
            if (state.items.isEmpty) {
              return const Center(child: Text('Cart is empty'));
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: item.imageUrl != null
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image),
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(item.name[0].toUpperCase()),
                                ),
                          title: Text(item.name),
                          subtitle: Text('\$${item.price.toStringAsFixed(2)} x ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  context.read<CartCubit>().updateQuantity(
                                    item.productId,
                                    item.quantity - 1,
                                  );
                                },
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  context.read<CartCubit>().updateQuantity(
                                    item.productId,
                                    item.quantity + 1,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  context.read<CartCubit>().removeItem(item.productId);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Checkout Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlocBuilder<CartCubit, CartState>(
                        builder: (context, cartState) {
                          if (cartState is CartUpdated) {
                            final total = context.read<CartCubit>().totalAmount;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _checkout(context),
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Error loading cart'));
        },
      ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to checkout')),
      );
      return;
    }

    final cartCubit = context.read<CartCubit>();
    final shopCubit = context.read<ShopCubit>();

    if (cartCubit.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    // Show shipping address dialog
    final addressController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shipping Address'),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Enter shipping address',
            hintText: '123 Main St, City, State, ZIP',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (result != true || addressController.text.isEmpty) {
      return;
    }

    try {
      // Convert cart items to order items
      final orderItems = cartCubit.items
          .map((item) => {
                'productId': item.productId,
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
              })
          .toList();

      // Create order
      await shopCubit.createOrder(
        userId: user.uid,
        items: orderItems,
        shippingAddress: addressController.text,
      );

      // Create transaction
      await shopCubit.createTransaction(
        userId: user.uid,
        orderId: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'purchase',
        amount: cartCubit.totalAmount,
        paymentMethod: 'credit_card',
      );

      // Clear cart
      cartCubit.clearCart();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

