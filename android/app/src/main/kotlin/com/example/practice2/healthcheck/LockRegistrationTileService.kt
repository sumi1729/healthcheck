package com.example.practice2.healthcheck

import android.app.PendingIntent
import android.content.Intent
import android.service.quicksettings.TileService

/// ロック画面からクイック設定経由で「登録画面」を開くためのタイル。
/// タップすると lock_mode=true を付けて MainActivity を起動する。
class LockRegistrationTileService : TileService() {
    override fun onClick() {
        super.onClick()

        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        // API 34+ では PendingIntent 版を使用する（Intent 版は非推奨）。
        startActivityAndCollapse(pendingIntent)
    }
}
