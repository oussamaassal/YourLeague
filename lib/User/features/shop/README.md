# Shop Feature

This feature provides CRUD operations for products, orders, and transactions using Firebase.

## Structure

```
shop/
├── domain/
│   ├── entities/           # Product, Order, Transaction models
│   └── repos/             # ShopRepo interface
├── data/
│   └── firebase_shop_repo.dart  # Firebase implementation
├── presentation/
│   ├── cubits/            # ShopCubit and states
│   └── pages/             # UI pages
└── README.md
```

## Usage

### Accessing the Shop Cubit

```dart
// Get the ShopCubit from context
final shopCubit = context.read<ShopCubit>();

// Or use BlocBuilder to listen to state changes
BlocBuilder<ShopCubit, ShopState>(
  builder: (context, state) {
    // Handle states
    if (state is ProductsLoaded) {
      return YourWidget(products: state.products);
    }
    return LoadingIndicator();
  },
)
```

### Product Operations

#### Create Product
```dart
shopCubit.createProduct(
  name: 'Football Jersey',
  description: 'Official team jersey',
  price: 49.99,
  stockQuantity: 100,
  category: 'Apparel',
);
```

#### Get All Products
```dart
shopCubit.getAllProducts();
```

#### Get Products by Category
```dart
shopCubit.getProductsByCategory('Apparel');
```

#### Update Product
```dart
final updatedProduct = Product(
  id: product.id,
  name: 'Updated Name',
  description: product.description,
  price: product.price,
  stockQuantity: product.stockQuantity,
  category: product.category,
  isAvailable: product.isAvailable,
  createdAt: product.createdAt,
);
shopCubit.updateProduct(updatedProduct);
```

#### Delete Product
```dart
shopCubit.deleteProduct(productId);
```

### Order Operations

#### Create Order
```dart
shopCubit.createOrder(
  userId: currentUser.uid,
  items: [
    {
      'productId': '123',
      'name': 'Football Jersey',
      'price': 49.99,
      'quantity': 2,
    },
  ],
  shippingAddress: '123 Main St, City, Country',
);
```

#### Get User Orders
```dart
shopCubit.getUserOrders(userId);
```

#### Get All Orders (Admin)
```dart
shopCubit.getAllOrders();
```

#### Update Order Status
```dart
final updatedOrder = Order(
  id: order.id,
  userId: order.userId,
  items: order.items,
  totalAmount: order.totalAmount,
  status: 'completed', // new status
  shippingAddress: order.shippingAddress,
  createdAt: order.createdAt,
  completedAt: Timestamp.now(),
);
shopCubit.updateOrder(updatedOrder);
```

### Transaction Operations

#### Create Transaction
```dart
shopCubit.createTransaction(
  userId: currentUser.uid,
  orderId: order.id,
  type: 'purchase',
  amount: 99.98,
  paymentMethod: 'credit_card',
);
```

#### Get User Transactions
```dart
shopCubit.getUserTransactions(userId);
```

#### Update Transaction
```dart
final updatedTransaction = Transaction(
  id: transaction.id,
  userId: transaction.userId,
  orderId: transaction.orderId,
  type: transaction.type,
  amount: transaction.amount,
  paymentMethod: transaction.paymentMethod,
  status: 'completed', // updated status
  createdAt: transaction.createdAt,
  transactionId: transaction.transactionId,
);
shopCubit.updateTransaction(updatedTransaction);
```

## UI Pages

### Products Page
Navigate to products page:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ProductsPage()),
);
```

### Orders Page
Navigate to orders page:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const OrdersPage()),
);
```

## States

The ShopCubit emits the following states:

- `ShopInitial` - Initial state
- `ShopLoading` - Loading operation
- `ProductsLoaded(List<Product>)` - Products loaded
- `ProductLoaded(Product)` - Single product loaded
- `OrdersLoaded(List<Order>)` - Orders loaded
- `OrderLoaded(Order)` - Single order loaded
- `TransactionsLoaded(List<Transaction>)` - Transactions loaded
- `TransactionLoaded(Transaction)` - Single transaction loaded
- `OperationSuccess(String)` - Operation completed successfully
- `ShopError(String)` - Error occurred

## Firebase Collections

The implementation uses the following Firestore collections:

- `products` - Stores product data
- `orders` - Stores order data
- `transactions` - Stores transaction data

Make sure to set up appropriate Firestore security rules for these collections.

