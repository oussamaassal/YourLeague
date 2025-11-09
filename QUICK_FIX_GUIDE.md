# 🚀 Quick Fix Guide - Stripe on Physical Device

## ⚡ Fast Rebuild Steps

```bash
# 1. Clean everything
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Uninstall from phone (manually)

# 4. Run in release mode
flutter run --release
```

## 🔍 Must Check Before Testing

1. ✅ **Server running?** → `cd server && node index.js`
2. ✅ **Same WiFi?** → Phone and computer on same network
3. ✅ **Correct IP?** → Check `lib/config/api_config.dart`
4. ✅ **Test from phone browser:** `http://YOUR_IP:3000/health`

## 📱 What You Should See

### ✅ GOOD Signs (It's Working!)
- Payment sheet opens **inside your app**
- Console logs show: `🟢 Presenting payment sheet...`
- After payment: Green success message
- App **stays open** the whole time
- Cart clears after payment

### ❌ BAD Signs (Still Broken)
- Payment opens in **browser**
- App **closes** when payment starts
- No green 🟢 logs in console
- Red error messages
- "Lost connection" errors

## 🧪 Test Card
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/25)
CVC: Any 3 digits (e.g., 123)
ZIP: Any 5 digits (e.g., 12345)
```

## 🐛 If Still Failing

### Option 1: Check Logs
```bash
flutter logs
```
Look for errors with "Stripe" or "🔴"

### Option 2: Nuclear Clean
```bash
flutter clean
cd android
./gradlew clean
cd ..
# Manually uninstall app
flutter run --release
```

### Option 3: Check Device Settings
- Settings → Apps → YourLeague → Battery → **Don't optimize**
- Developer Options → "Don't keep activities" → **OFF**

## 📊 Key Changes Made

| Component | Old | New | Why |
|-----------|-----|-----|-----|
| Launch Mode | singleTop | **singleTask** | Prevents app restart |
| Intent Handler | None | **Custom handler** | Catches Stripe redirect |
| Payment Config | Basic | **+ Google Pay** | Alternative payment |
| Activity State | Default | **alwaysRetain** | Keeps app alive |

## 🎯 The Problem

**Simulator**: Works fine (lenient memory management)  
**Physical Device**: App closes (aggressive task killing)

**Solution**: Make Android treat your app as a persistent single task that shouldn't be killed.

## 📞 Debug Checklist

```bash
# 1. Is server reachable?
curl http://YOUR_IP:3000/health

# 2. Is device connected?
flutter devices

# 3. Are there build errors?
flutter doctor

# 4. Check real-time logs
flutter logs | grep -i stripe

# 5. Check Android specifically
adb logcat | grep yourleague
```

## 🎬 Expected Flow

1. User clicks "Checkout"
2. Loading spinner shows
3. Console: `🟢 Starting payment process...`
4. Console: `🟢 Backend is reachable`
5. Console: `🟢 Payment intent created`
6. Console: `🟢 Initializing payment sheet...`
7. Payment sheet opens **IN-APP** ← **Critical!**
8. User enters card `4242 4242 4242 4242`
9. Console: `🟢 Payment sheet completed`
10. **App still open!** ← **Critical!**
11. Green success message shows
12. Cart clears
13. Done! ✅

## ⚠️ Common Mistakes

❌ **Forgetting to restart server** after code changes  
❌ **Wrong IP address** in api_config.dart  
❌ **Device on different WiFi** than computer  
❌ **Testing in debug mode** instead of release  
❌ **Battery optimization killing app**  
❌ **Not uninstalling old version** before testing  

## 💡 Pro Tips

1. **Always test in `--release` mode** on physical devices
2. **Watch console logs** while testing - they tell the story
3. **Disable battery optimization** for your app during testing
4. **Use same WiFi** for phone and computer
5. **Completely uninstall** between tests to avoid cached issues

---

**Quick Question Test:**
- Does payment sheet open in a **separate browser?** → ❌ Still broken
- Does payment sheet open **inside your app?** → ✅ Working!

---

Last Updated: November 9, 2025
