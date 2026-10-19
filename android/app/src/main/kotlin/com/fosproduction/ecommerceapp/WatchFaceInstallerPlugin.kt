package com.fosproduction.ecommerceapp

import android.content.Intent
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class WatchFaceInstallerPlugin(private val activity: MainActivity) :
    MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "WatchFace"
        private const val CHANNEL = "watch_face_installer"
        private const val GALAXY_WEARABLE = "com.samsung.android.app.watchmanager"

        fun registerWith(engine: FlutterEngine, activity: MainActivity) {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(WatchFaceInstallerPlugin(activity))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installAndroidWatchFace" -> {
                val fileName = call.argument<String>("fileName")
                val filePath = call.argument<String>("filePath")
                if (fileName.isNullOrBlank()) {
                    result.error("BAD_ARGS", "Expected a 'fileName' argument.", null)
                    return
                }
                installAndroidWatchFace(fileName, filePath, result)
            }

            else -> result.notImplemented()
        }
    }

    private fun installAndroidWatchFace(
        fileName: String,
        filePath: String?,
        result: MethodChannel.Result,
    ) {
        Log.i(TAG, "install start fileName=$fileName filePath=$filePath")
        val file = resolveWatchFaceFile(fileName, filePath)
        if (file == null) {
            Log.e(TAG, "file not found fileName=$fileName filePath=$filePath")
            result.error(
                "FILE_NOT_FOUND",
                "Could not find $fileName in app storage.",
                null,
            )
            return
        }

        Log.i(TAG, "file ok path=${file.absolutePath} size=${file.length()}")

        try {
            val uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                file,
            )
            Log.i(TAG, "fileProvider uri=$uri")
            val baseIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/octet-stream")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val galaxyIntent = Intent(baseIntent).apply {
                setPackage(GALAXY_WEARABLE)
            }
            if (galaxyIntent.resolveActivity(activity.packageManager) != null) {
                Log.i(TAG, "opening Galaxy Wearable package=$GALAXY_WEARABLE")
                activity.startActivity(galaxyIntent)
                result.success(
                    mapOf(
                        "success" to true,
                        "message" to
                            "Opening Galaxy Wearable. Tap Install to add the watch face.",
                    ),
                )
                return
            }

            if (baseIntent.resolveActivity(activity.packageManager) != null) {
                Log.i(TAG, "Galaxy Wearable missing, showing chooser")
                activity.startActivity(
                    Intent.createChooser(baseIntent, "Install watch face"),
                )
                result.success(
                    mapOf(
                        "success" to true,
                        "message" to
                            "Choose Galaxy Wearable to install the watch face.",
                    ),
                )
                return
            }

            Log.e(TAG, "no app can handle watch face intent")
            result.error(
                "NO_HANDLER",
                "Install Galaxy Wearable, pair your watch, then try again.",
                null,
            )
        } catch (e: Exception) {
            Log.e(TAG, "install failed", e)
            result.error("INSTALL_FAILED", e.message, null)
        }
    }

    private fun resolveWatchFaceFile(fileName: String, filePath: String?): File? {
        if (!filePath.isNullOrBlank()) {
            val direct = File(filePath)
            Log.i(
                TAG,
                "resolve filePath=$filePath exists=${direct.exists()} length=${if (direct.exists()) direct.length() else 0}",
            )
            if (direct.exists() && direct.length() > 0L) return direct
        }
        Log.e(TAG, "resolve failed fileName=$fileName filePath=$filePath")
        return null
    }
}
