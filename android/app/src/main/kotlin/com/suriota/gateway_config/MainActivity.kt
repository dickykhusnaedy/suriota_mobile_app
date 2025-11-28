package com.suriota.gateway_config

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gateway.config/file_manager"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFileManager" -> {
                    val directoryPath = call.argument<String>("directoryPath")
                    if (directoryPath != null) {
                        openFileManager(directoryPath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Directory path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun openFileManager(directoryPath: String, result: MethodChannel.Result) {
        try {
            val directory = File(directoryPath)

            // Create intent to view directory
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(
                Uri.parse("content://com.android.externalstorage.documents/document/primary:${getRelativePath(directoryPath)}"),
                "resource/folder"
            )
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION

            // Try to open with DocumentsUI
            try {
                startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                // Fallback: Open generic file manager
                val fallbackIntent = Intent(Intent.ACTION_VIEW)
                fallbackIntent.setDataAndType(Uri.parse(directoryPath), "*/*")
                fallbackIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

                try {
                    startActivity(fallbackIntent)
                    result.success(true)
                } catch (ex: Exception) {
                    result.error("FAILED", "Cannot open file manager: ${ex.message}", null)
                }
            }
        } catch (e: Exception) {
            result.error("ERROR", "Error opening file manager: ${e.message}", null)
        }
    }

    private fun getRelativePath(fullPath: String): String {
        return if (fullPath.contains("/storage/emulated/0/")) {
            fullPath.replace("/storage/emulated/0/", "")
        } else {
            fullPath
        }
    }
}
