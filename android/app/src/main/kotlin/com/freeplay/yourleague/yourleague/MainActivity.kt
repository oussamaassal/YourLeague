package com.freeplay.yourleague.yourleague

import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.Intent
import android.os.Bundle

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle deep links for Stripe return
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle deep links when app is already running
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        // This ensures Stripe deep links are properly handled
        intent?.data?.let { uri ->
            if (uri.scheme == "yourleague" && uri.host == "stripe-redirect") {
                // Stripe will handle this automatically via its SDK
                // We just need to keep the activity alive
            }
        }
    }
}
