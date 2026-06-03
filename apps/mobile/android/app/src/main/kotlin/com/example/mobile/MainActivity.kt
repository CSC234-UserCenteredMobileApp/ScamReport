package com.example.mobile

import android.content.IntentFilter
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth for
// the biometric prompt; without it local_auth throws `no_fragment_activity`.
class MainActivity : FlutterFragmentActivity() {

    private var smsReceiver: SmsReceiver? = null
    private lateinit var callScreeningChannel: CallScreeningChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        callScreeningChannel = CallScreeningChannel(this)
        callScreeningChannel.register(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.scamreport/sms_events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    smsReceiver?.let { unregisterReceiver(it) }
                    smsReceiver = SmsReceiver(sink).also { receiver ->
                        ContextCompat.registerReceiver(
                            this@MainActivity,
                            receiver,
                            IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION),
                            ContextCompat.RECEIVER_EXPORTED,
                        )
                    }
                }

                override fun onCancel(arguments: Any?) {
                    smsReceiver?.let { unregisterReceiver(it) }
                    smsReceiver = null
                }
            })
    }
}
