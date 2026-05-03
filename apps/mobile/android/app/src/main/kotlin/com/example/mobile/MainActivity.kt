package com.example.mobile

import android.content.IntentFilter
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private var smsReceiver: SmsReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.scamreport/sms_events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    smsReceiver = SmsReceiver(sink).also { receiver ->
                        registerReceiver(
                            receiver,
                            IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION),
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
