import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../components/drawer.dart';
import '../../../shop/presentation/pages/products_page.dart';
import '../../../shop/presentation/pages/cart_page.dart';
import '../../../shop/presentation/cubits/shop_cubit.dart';
import '../../../shop/presentation/cubits/cart_cubit.dart';
import '../../../shop/presentation/cubits/cart_states.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Tab controller
  late final _tabController = TabController(length: 3, vsync: this);
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // SCAFFOLD
    return Scaffold(
      // APP BAR
      appBar: AppBar(
        title: const Text("Home page"),
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          // Cart Icon with Badge
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    if (state is CartUpdated && state.items.isNotEmpty) {
                      final itemCount = context.read<CartCubit>().itemCount;
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          labelColor: Theme.of(context).colorScheme.inversePrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: "Page 1"),
            Tab(text: "Page 2"),
            Tab(text: "Page 3"),
          ],
        ),
      ),

      // DRAWER
      drawer: const MyDrawer(),

      // FLOATING ACTION BUTTON
      floatingActionButton: _currentTabIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => BlocProvider.value(
                    value: context.read<ShopCubit>(),
                    child: const AddProductDialog(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,

      // BODY - Tab Content
      body: TabBarView(
        controller: _tabController,
        children: [
          // Page 1 - Placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Page 1 - Home',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome to Your League',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),

          // Page 2 - Placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Page 2 - Explore',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Discover and Explore',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),

          // Page 3 - Shop (Products Page)
          const ProductsPage(showAppBar: false),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}