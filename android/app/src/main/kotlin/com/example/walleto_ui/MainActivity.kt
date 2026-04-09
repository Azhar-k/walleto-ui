package com.example.walleto_ui

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.walleto.sms/scan"
    private val TAG = "WalletoSmsNative"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getRcsMessages") {
                val startTime = call.argument<Long>("startTime") ?: 0L
                val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                Log.d(TAG, "Fetching RCS messages from $startTime to $endTime")
                val messages = getRcsMessages(startTime, endTime)
                Log.d(TAG, "Found ${messages.size} RCS messages")
                result.success(messages)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getRcsMessages(startTime: Long, endTime: Long): List<Map<String, Any?>> {
        val messages = mutableListOf<Map<String, Any?>>()
        val contentResolver = contentResolver
        val mmsUri = Uri.parse("content://mms")

        // m_type = 132 is standard for RCS messages in many Android implementations
        val selection = "m_type = ? AND msg_box = ? AND date >= ? AND date <= ?"
        val selectionArgs = arrayOf(
            "132",
            "1", // Inbox
            (startTime / 1000).toString(), // MMS uses seconds
            (endTime / 1000).toString()
        )

        val cursor = contentResolver.query(
            mmsUri,
            arrayOf("_id", "date", "thread_id"),
            selection,
            selectionArgs,
            "date DESC"
        )

        cursor?.use {
            Log.d(TAG, "MMS query returned ${it.count} potential messages")
            while (it.moveToNext()) {
                val mmsId = it.getLong(it.getColumnIndexOrThrow("_id"))
                val mmsDateSec = it.getLong(it.getColumnIndexOrThrow("date"))
                val threadId = it.getLong(it.getColumnIndexOrThrow("thread_id"))

                val body = getMmsText(contentResolver, mmsId)
                val sender = getThreadAddress(contentResolver, threadId)

                Log.d(TAG, "Processing message ID: $mmsId, Thread: $threadId, Sender: $sender")

                if (body.isNotEmpty()) {
                    messages.add(mapOf(
                        "sender" to sender,
                        "body" to body,
                        "timestamp" to mmsDateSec * 1000 // Convert back to milliseconds for Flutter
                    ))
                }
            }
        } ?: Log.e(TAG, "MMS cursor is null")
        return messages
    }

    private fun getMmsText(contentResolver: ContentResolver, mmsId: Long): String {
        val partUri = Uri.parse("content://mms/part")
        val selection = "mid = ?"
        val selectionArgs = arrayOf(mmsId.toString())
        val body = StringBuilder()

        val cursor = contentResolver.query(
            partUri,
            arrayOf("ct", "text"),
            selection,
            selectionArgs,
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                val contentType = it.getString(it.getColumnIndexOrThrow("ct"))
                if (contentType == "text/plain") {
                    val partText = it.getString(it.getColumnIndexOrThrow("text"))
                    if (partText != null) {
                        if (body.length > 0) body.append(" ")
                        body.append(partText)
                    }
                }
            }
        }
        return body.toString()
    }

    private fun getThreadAddress(contentResolver: ContentResolver, threadId: Long): String {
        var address = ""

        Log.d(TAG, "Resolving address for thread_id: $threadId")

        // 1. Try SMS table
        try {
            val smsUri = Uri.parse("content://sms")
            val smsCursor = contentResolver.query(
                smsUri,
                arrayOf("address"),
                "thread_id = ?",
                arrayOf(threadId.toString()),
                "_id DESC LIMIT 1"
            )

            smsCursor?.use {
                if (it.moveToFirst()) {
                    address = it.getString(it.getColumnIndexOrThrow("address")) ?: ""
                    Log.d(TAG, "Found address in SMS table: $address")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying SMS table: ${e.message}")
        }

        // 2. Try canonical addresses
        if (address.isEmpty()) {
            try {
                val threadsUri = Uri.parse("content://mms-sms/conversations")
                // Use * to avoid "no such column" errors if specific columns aren't present
                // and then manually check for what we need.
                val threadsCursor = contentResolver.query(
                    threadsUri,
                    null, // Query all columns to see what's available
                    "_id = ?",
                    arrayOf(threadId.toString()),
                    null
                )

                threadsCursor?.use {
                    if (it.moveToFirst()) {
                        // Log columns for debugging
                        // Log.d(TAG, "Available columns in threads: ${it.columnNames.joinToString(", ")}")

                        val recipientIdIdx = it.getColumnIndex("recipient_ids")
                        if (recipientIdIdx != -1) {
                            val recipientIds = it.getString(recipientIdIdx)
                            if (!recipientIds.isNullOrEmpty()) {
                                Log.d(TAG, "Found recipientIds: $recipientIds")
                                val canonicalUri = Uri.parse("content://mms-sms/canonical-addresses")
                                val canonicalCursor = contentResolver.query(
                                    canonicalUri,
                                    arrayOf("address"),
                                    "_id = ?",
                                    arrayOf(recipientIds),
                                    null
                                )
                                canonicalCursor?.use { c ->
                                    if (c.moveToFirst()) {
                                        address = c.getString(c.getColumnIndexOrThrow("address")) ?: ""
                                        Log.d(TAG, "Found address in canonical table: $address")
                                    }
                                }
                            }
                        } else {
                            Log.e(TAG, "Column 'recipient_ids' not found in threads table")
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error querying threads/canonical table: ${e.message}")
            }
        }
        return address
    }
}
