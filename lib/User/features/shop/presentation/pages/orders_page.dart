import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/shop_cubit.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/shop_states.dart';
import 'package:yourleague/User/features/shop/data/firebase_shop_repo.dart';
import 'package:yourleague/User/features/shop/domain/entities/order.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return BlocProvider(
      create: (context) {
        final cubit = ShopCubit(shopRepo: FirebaseShopRepo());
        if (currentUser != null) {
          cubit.getUserOrders(currentUser.uid);
        }
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
        ),
        body: BlocBuilder<ShopCubit, ShopState>(
          builder: (context, state) {
            if (state is ShopLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OrdersLoaded) {
              if (state.orders.isEmpty) {
                return const Center(child: Text('No orders yet'));
              }

              return ListView.builder(
                itemCount: state.orders.length,
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(order.status),
                        child: Text(order.status[0].toUpperCase()),
                      ),
                      title: Text('Order #${order.id.substring(order.id.length - 8)}'),
                      subtitle: Text(
                        'Total: \$${order.totalAmount.toStringAsFixed(2)}\n'
                        'Status: ${order.status}\n'
                        'Items: ${order.items.length}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          // View order details
                          showDialog(
                            context: context,
                            builder: (context) => OrderDetailsDialog(order: order),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            }

            if (state is ShopError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            return const Center(child: Text('No data'));
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Order Details Dialog
class OrderDetailsDialog extends StatelessWidget {
  final Order order;
  
  const OrderDetailsDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Order ID', order.id),
              _buildInfoRow('Status', order.status),
              _buildInfoRow('Total', '\$${order.totalAmount.toStringAsFixed(2)}'),
              _buildInfoRow('Shipping', order.shippingAddress),
              const SizedBox(height: 8),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• ${item['name']} x${item['quantity']} - \$${item['price']}'),
                  )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

