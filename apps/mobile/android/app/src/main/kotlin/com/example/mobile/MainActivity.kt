package com.example.mobile

import android.content.IntentFilter
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

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
                            ContextCompat.RECEIVER_NOT_EXPORTED,
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
