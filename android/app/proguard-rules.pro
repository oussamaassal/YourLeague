# Stripe ProGuard rules
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Keep model classes
-keep class com.stripe.android.model.** { *; }

# Keep PaymentConfiguration
-keep class com.stripe.android.PaymentConfiguration { *; }

# Keep 3DS authentication classes
-keep class com.stripe.android.stripe3ds2.** { *; }

# Keep Stripe API version
-keepattributes SourceFile,LineNumberTable