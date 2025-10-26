# Shop Feature - Architecture Flow Diagram

## 🏗️ Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │  Products    │    │     Cart     │    │  Checkout    │    │
│  │    Page      │    │     Page     │    │   Dialog     │    │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘    │
│         │                   │                   │             │
│         │ (list products)   │ (view cart)       │ (enter addr)│
│         ▼                   ▼                   ▼             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │   + Button    │    │  Qty Controls│    │  Submit      │   │
│  └──────────────┘    └───────────────┘    └──────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STATE MANAGEMENT (CUBITS)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────┐             │
│  │           ShopCubit                          │             │
│  │  • getAllProducts()                          │             │
│  │  • createProduct()                           │             │
│  │  • updateProduct()                           │             │
│  │  • deleteProduct()                            │             │
│  │  • createOrder()                              │             │
│  │  • createTransaction()                        │             │
│  └─────────────────────────────────────────────┘             │
│                                                                 │
│  ┌─────────────────────────────────────────────┐             │
│  │           CartCubit                          │             │
│  │  • addItem()                                  │             │
│  │  • removeItem()                               │             │
│  │  • updateQuantity()                           │             │
│  │  • clearCart()                                │             │
│  │  • get itemCount, totalAmount                 │             │
│  └─────────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REPOSITORY LAYER (INTERFACES)                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    ShopRepo Interface                          │
│                    (Abstract class)                             │
│  • createProduct(Product)                                      │
│  • getAllProducts()                                             │
│  • updateProduct(Product)                                       │
│  • deleteProduct(String)                                       │
│  • createOrder(Order)                                           │
│  • getUserOrders(String)                                        │
│  • createTransaction(Transaction)                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER (FIREBASE)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│              FirebaseShopRepo (Implementation)                  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │  Firestore Collections:                               │    │
│  │  • products    → Product documents                    │    │
│  │  • orders      → Order documents                      │    │
│  │  • transactions → Transaction documents              │    │
│  └───────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FIREBASE FIRESTORE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📁 products/                                                   │
│    ├── 📄 product_1 → {name, price, stock, image...}           │
│    ├── 📄 product_2 → {name, price, stock, image...}           │
│    └── 📄 product_n → {name, price, stock, image...}           │
│                                                                 │
│  📁 orders/                                                     │
│    ├── 📄 order_1 → {userId, items, total, status...}         │
│    ├── 📄 order_2 → {userId, items, total, status...}          │
│    └── 📄 order_n → {userId, items, total, status...}          │
│                                                                 │
│  📁 transactions/                                               │
│    ├── 📄 transaction_1 → {userId, orderId, amount...}        │
│    ├── 📄 transaction_2 → {userId, orderId, amount...}           │
│    └── 📄 transaction_n → {userId, orderId, amount...}          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Examples

### **1. Adding a Product Flow:**
```
User Action:
  Click "+" button → Fill form → Click "Add"

Flow:
  UI Dialog
    → ShopCubit.createProduct()
    → shopRepo.createProduct(product)
    → FirebaseFirestore.collection('products').doc(id).set(data)
    → Firestore Database
    → UI updates (product appears in list)
```

### **2. Adding to Cart Flow:**
```
User Action:
  Click cart icon on product

Flow:
  ProductsPage
    → Creates CartItem
    → CartCubit.addItem(cartItem)
    → CartCubit updates internal list
    → CartCubit emits CartUpdated state
    → UI updates (badge shows count)
```

### **3. Checkout Flow:**
```
User Action:
  View cart → Click "Checkout" → Enter address → Click "Continue"

Flow:
  CartPage._checkout()
    → ShopCubit.createOrder(orderData)
      → FirebaseShopRepo.createOrder(order)
      → FirebaseFirestore.collection('orders').doc(id).set(data)
    → ShopCubit.createTransaction(transactionData)
      → FirebaseShopRepo.createTransaction(transaction)
      → FirebaseFirestore.collection('transactions').doc(id).set(data)
    → CartCubit.clearCart()
    → Show success message
    → Navigate back
```

---

## 📊 State Management Flow

### **ShopCubit States:**
```
Initial → Loading → ProductsLoaded/ShopError
                  ↓
           OperationSuccess
```

### **CartCubit States:**
```
Initial → CartUpdated (with items list)
```

---

## 🎯 Key Integration Points

### **main.dart:**
- Registers ShopCubit, CartCubit in MultiBlocProvider
- Provides to entire app via widget tree

### **home_page.dart:**
- Integrates ProductsPage in Page 3 tab
- Adds cart icon with badge in app bar
- Shows cart count from CartCubit

### **products_page.dart:**
- Displays all products
- Connects to ShopCubit for product operations
- Connects to CartCubit for add to cart
- Shows images and product details

### **cart_page.dart:**
- Displays cart items
- Connects to CartCubit for cart operations
- Connects to ShopCubit for checkout
- Handles checkout flow

---

## 🔐 Security & Best Practices

### **Used Patterns:**
✅ Clean Architecture - Separation of concerns
✅ Repository Pattern - Abstraction layer
✅ BLoC/Cubit Pattern - State management
✅ Dependency Injection - via BlocProvider
✅ Error Handling - Try-catch blocks
✅ Type Safety - Strong typing with Dart

### **Future Enhancements:**
- Add Firebase Storage for image uploads
- Add authentication checks for admin actions
- Add order status updates
- Add payment gateway integration
- Add email notifications

