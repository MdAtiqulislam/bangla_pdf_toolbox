package com.banglapdftools.bangla_pdf_toolbox

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.banglapdftools.bangla_pdf_toolbox/intent"
    private var pendingPdfData: Map<String, String>? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialPdf" -> {
                    val data = pendingPdfData
                    pendingPdfData = null
                    result.success(data)
                }
                "resolveContentUri" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr != null) {
                        val resolved = processUri(Uri.parse(uriStr))
                        result.success(resolved)
                    } else {
                        result.success(null)
                    }
                }
                "queryAllPdfs" -> {
                    Thread {
                        val list = queryAllPdfs()
                        runOnUiThread {
                            result.success(list)
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }

        // If an intent was captured before Flutter engine initialized, dispatch it
        pendingPdfData?.let {
            methodChannel?.invokeMethod("onPdfOpened", it)
        }
    }

    private fun queryAllPdfs(): List<Map<String, Any>> {
        val pdfList = mutableListOf<Map<String, Any>>()
        val uri = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DATA,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.DATE_MODIFIED
        )
        val selection = "${MediaStore.Files.FileColumns.MIME_TYPE} = ? OR ${MediaStore.Files.FileColumns.DATA} LIKE ?"
        val selectionArgs = arrayOf("application/pdf", "%.pdf")
        val sortOrder = "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"

        try {
            contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
                val idIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val dataIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)
                val nameIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
                val dateIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)

                while (cursor.moveToNext()) {
                    val path = cursor.getString(dataIndex)
                    val name = cursor.getString(nameIndex) ?: (path?.substringAfterLast("/") ?: "Document.pdf")
                    val size = cursor.getLong(sizeIndex)
                    val dateModified = cursor.getLong(dateIndex)

                    if (path != null && File(path).exists() && size > 100) {
                        pdfList.add(mapOf(
                            "id" to "${cursor.getLong(idIndex)}_$name",
                            "path" to path,
                            "fileName" to name,
                            "sizeInBytes" to size,
                            "modifiedDate" to dateModified * 1000
                        ))
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return pdfList
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action

        var uri: Uri? = null
        if (Intent.ACTION_VIEW == action || Intent.ACTION_EDIT == action) {
            uri = intent.data
        } else if (Intent.ACTION_SEND == action) {
            uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM) ?: intent.data
        }

        if (uri != null) {
            val resultData = processUri(uri)
            if (resultData != null) {
                pendingPdfData = resultData
                methodChannel?.invokeMethod("onPdfOpened", resultData)
            }
        }
    }

    private fun processUri(uri: Uri): Map<String, String>? {
        return try {
            val scheme = uri.scheme
            var fileName = "Document.pdf"

            if ("content".equals(scheme, ignoreCase = true)) {
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1 && cursor.moveToFirst()) {
                        fileName = cursor.getString(nameIndex) ?: "Document.pdf"
                    }
                }
            } else if ("file".equals(scheme, ignoreCase = true)) {
                val path = uri.path
                if (path != null) {
                    val file = File(path)
                    if (file.exists() && file.length() > 0) {
                        return mapOf("path" to file.absolutePath, "title" to file.name)
                    }
                    fileName = file.name
                }
            }

            if (!fileName.endsWith(".pdf", ignoreCase = true)) {
                fileName = "$fileName.pdf"
            }

            val sanitizedName = fileName.replace(Regex("[^a-zA-Z0-9._-]"), "_")
            val targetFile = File(cacheDir, "intent_$sanitizedName")

            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(targetFile).use { output ->
                    input.copyTo(output)
                }
            }

            if (targetFile.exists() && targetFile.length() > 0) {
                mapOf("path" to targetFile.absolutePath, "title" to fileName)
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
