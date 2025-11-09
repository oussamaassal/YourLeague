#!/bin/bash

# Stripe Payment Fix - Quick Rebuild Script
# Run this to completely rebuild your app after the fixes

echo "🧹 Cleaning Flutter build cache..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "✅ Clean and dependencies complete!"
echo ""
echo "📱 NEXT STEPS:"
echo "1. Manually UNINSTALL the app from your physical device"
echo "2. Make sure your backend server is running: cd server && node index.js"
echo "3. Verify device and computer are on the same WiFi"
echo "4. Run: flutter run --release"
echo ""
echo "🧪 TEST CARD: 4242 4242 4242 4242"
echo ""
echo "Expected: Payment sheet opens IN-APP and app stays open!"
