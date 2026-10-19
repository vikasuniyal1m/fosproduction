package com.fosproduction.ecommerceapp

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WatchFaceInstallerPlugin.registerWith(flutterEngine, this)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        logAppSigningSha1()
    }

    private fun logAppSigningSha1() {
        try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager
                    .getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                    .signingInfo
                    ?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageManager
                    .getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                    .signatures
            }

            signatures?.forEach { signature ->
                val digest = MessageDigest.getInstance("SHA-1").digest(signature.toByteArray())
                val sha1 = digest.joinToString(":") { byte -> "%02X".format(byte) }
                Log.i("SIGNING_SHA1", "GCP Android OAuth SHA-1 must be: $sha1")
            }
        } catch (e: Exception) {
            Log.e("SIGNING_SHA1", "Failed to read signing certificate", e)
        }
    }
}
