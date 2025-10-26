# How to View the Database - Firebase Console Guide

## Step-by-Step Instructions

### 1. Access Firebase Console
- Open your browser and go to: **https://console.firebase.google.com/**
- Sign in with your Google account that has access to the project

### 2. Select Your Project
- Click on your project: **footapp-c17ca**

### 3. Navigate to Firestore Database
- In the left sidebar, click on **"Firestore Database"** or **"Build" → "Firestore Database"**

### 4. View Collections
You'll see three main collections:
- **products** - All products in your shop
- **orders** - All customer orders
- **transactions** - All payment transactions

### 5. Browse Data

#### View Products:
1. Click on the **products** collection
2. You'll see documents (one per product) with fields like:
   - `name`: Product name
   - `price`: Product price
   - `description`: Product description
   - `category`: Product category
   - `stockQuantity`: Available stock
   - `isAvailable`: true/false
   - `imageUrl`: URL to product image
   - `createdAt`: When product was created

#### View Orders:
1. Click on the **orders** collection
2. You'll see documents (one per order) with fields like:
   - `userId`: Who made the order
   - `items`: List of items in the order
   - `totalAmount`: Total price
   - `status`: pending/processing/completed/cancelled
   - `shippingAddress`: Delivery address
   - `createdAt`: When order was placed
   - `completedAt`: When order was completed (if applicable)

#### View Transactions:
1. Click on the **transactions** collection
2. You'll see documents (one per transaction) with fields like:
   - `userId`: Who made the transaction
   - `orderId`: Associated order ID
   - `amount`: Transaction amount
   - `type`: purchase/refund/exchange
   - `paymentMethod`: credit_card/paypal/etc
   - `status`: pending/completed/failed
   - `createdAt`: When transaction occurred

## How to Test Data Creation

### Adding a Product via the App:
1. Run your Flutter app
2. Navigate to Page 3 (Shop tab)
3. Click the **floating + button**
4. Fill in the form:
   - Name: "Football Jersey"
   - Description: "Official team jersey"
   - Price: "49.99"
   - Stock Quantity: "100"
   - Category: "Apparel"
   - Image URL: "https://example.com/jersey.jpg" (optional)
5. Click "Add"
6. **Refresh Firebase Console** to see the new product in the database

### Placing an Order:
1. Browse products on Page 3
2. Click the **cart icon** on any product to add to cart
3. Click the **cart icon** in the top-right app bar
4. Click **"Checkout"**
5. Enter a shipping address
6. Click "Continue"
7. **Refresh Firebase Console** to see the new order and transaction

## Visual Screenshots Locations in Firebase Console

### Products Collection:
```
📁 firestore
  └── 📁 products
      └── 📄 [Product ID]
          ├── name: "Football Jersey"
          ├── price: 49.99
          ├── description: "Official team jersey"
          ├── category: "Apparel"
          ├── stockQuantity: 100
          ├── isAvailable: true
          ├── imageUrl: "https://..."
          └── createdAt: [Timestamp]
```

### Orders Collection:
```
📁 firestore
  └── 📁 orders
      └── 📄 [Order ID]
          ├── userId: "user123..."
          ├── items: [{productId, name, price, quantity}, ...]
          ├── totalAmount: 99.98
          ├── status: "pending"
          ├── shippingAddress: "123 Main St"
          ├── createdAt: [Timestamp]
          └── completedAt: null
```

### Transactions Collection:
```
📁 firestore
  └── 📁 transactions
      └── 📄 [Transaction ID]
          ├── userId: "user123..."
          ├── orderId: "order456..."
          ├── type: "purchase"
          ├── amount: 99.98
          ├── paymentMethod: "credit_card"
          ├── status: "pending"
          ├── createdAt: [Timestamp]
          └── transactionId: null
```

## What to Show Your Audience Tomorrow

1. **Show the Firebase Console** - Navigate through products, orders, transactions
2. **Add a product live** - Use the app to add a product, then show it appearing in the database
3. **Place an order** - Add items to cart, checkout, then show the order and transaction created
4. **Explain the architecture** - Show how data flows:
   - **UI** (Products Page) → **Cubit** (ShopCubit/CartCubit) → **Repository** (FirebaseShopRepo) → **Firestore**

## Key Points to Explain

### Architecture:
- **Clean Architecture**: Domain → Data → Presentation layers
- **State Management**: BLoC/Cubit pattern for reactive UI
- **Firebase Integration**: Real-time database with Firestore

### Features:
- **CRUD Operations**: Create, Read, Update, Delete for all entities
- **Cart System**: Add, remove, update quantities
- **Checkout Flow**: Creates orders and transactions in database
- **Image Support**: Products can have images via URLs

### Database Structure:
- **3 Collections**: products, orders, transactions
- **Relationships**: Orders contain items, Transactions reference Orders
- **User Tracking**: All orders/transactions linked to user IDs

