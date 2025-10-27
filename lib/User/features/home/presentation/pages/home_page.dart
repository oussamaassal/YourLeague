import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../Stadiums/presentation/pages/AdminRentalsPage.dart';
import '../../../../../Stadiums/presentation/pages/admin_add_stadium_page.dart';
import '../../../../../Stadiums/presentation/pages/rent_stadium_page.dart';
import '../../../../components/drawer.dart';
import '../../../shop/presentation/pages/products_page.dart';
import '../../../shop/presentation/pages/cart_page.dart';
import '../../../shop/presentation/cubits/shop_cubit.dart';
import '../../../shop/presentation/cubits/cart_cubit.dart';
import '../../../shop/presentation/cubits/cart_states.dart';
import '../../../matches/presentation/pages/matches_page.dart';
import '../../../matches/presentation/pages/tournaments_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 6, vsync: this);
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home page"),
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                final itemCount = state is CartUpdated ? state.items.length : 0;
                return Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$itemCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.inversePrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.primary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: "Matches"),
                Tab(text: "Tournaments"),
                Tab(text: "Shop"),
                Tab(text: "Add Stadium"),
                Tab(text: "Rent"),
                Tab(text: "Rentals"),
              ],
            ),
          ),
        ),
      ),
      drawer: const MyDrawer(),
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
      body: IndexedStack(
        index: _currentTabIndex,
        children: const [
          MatchesPage(),
          TournamentsPage(),
          ProductsPage(showAppBar: false),
          AdminAddStadiumPage(),
          RentStadiumPage(),
          AdminRentalsPage(),
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
