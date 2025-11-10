# Stripe Payment Fix - Quick Rebuild Script (PowerShell)
# Run this to completely rebuild your app after the fixes

Write-Host "🧹 Cleaning Flutter build cache..." -ForegroundColor Yellow
flutter clean

Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "✅ Clean and dependencies complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Manually UNINSTALL the app from your physical device"
Write-Host "2. Make sure your backend server is running: cd server; node index.js"
Write-Host "3. Verify device and computer are on the same WiFi"
Write-Host "4. Run: flutter run --release"
Write-Host ""
Write-Host "🧪 TEST CARD: 4242 4242 4242 4242" -ForegroundColor Magenta
Write-Host ""
Write-Host "Expected: Payment sheet opens IN-APP and app stays open!" -ForegroundColor Green
