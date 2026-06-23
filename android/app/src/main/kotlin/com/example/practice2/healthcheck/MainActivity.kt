package com.example.practice2.healthcheck

import android.app.KeyguardManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.practice2.healthcheck/lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // 端末がロック中か（ロック画面の上に表示されているか）を返す。
                    // ロック中は実績を見せず登録のみ表示するための判定に使う。
                    "isDeviceLocked" -> {
                        val km =
                            getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                        result.success(km.isKeyguardLocked)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
