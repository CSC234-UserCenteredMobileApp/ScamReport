package com.example.mobile

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CallScreeningChannel(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.example.mobile/call_screening"
        const val REQUEST_ROLE = 1001
    }

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSdkVersion" -> result.success(Build.VERSION.SDK_INT)
            "isServiceDefault" -> result.success(isScreeningDefault())
            "openScreeningSettings" -> {
                openScreeningSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun isScreeningDefault(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val rm = activity.getSystemService(Context.ROLE_SERVICE) as RoleManager
        return rm.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun openScreeningSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val rm = activity.getSystemService(Context.ROLE_SERVICE) as RoleManager
        val intent = rm.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
        activity.startActivityForResult(intent, REQUEST_ROLE)
    }
}
