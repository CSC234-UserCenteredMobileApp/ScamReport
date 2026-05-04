package com.example.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var callScreeningChannel: CallScreeningChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callScreeningChannel = CallScreeningChannel(this)
        callScreeningChannel.register(flutterEngine)
    }
}
