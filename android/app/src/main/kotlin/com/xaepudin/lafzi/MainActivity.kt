package com.xaepudin.lafzi

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.speech.RecognizerIntent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var pendingResult: MethodChannel.Result? = null
    private var pendingLanguage: String? = null
    private var pendingPrompt: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SPEECH_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "recognize") {
                beginRecognition(
                    language = call.argument<String>("language") ?: "ar-AE",
                    prompt = call.argument<String>("prompt") ?: "",
                    result = result,
                )
            } else {
                result.notImplemented()
            }
        }
    }

    private fun beginRecognition(
        language: String,
        prompt: String,
        result: MethodChannel.Result,
    ) {
        if (pendingResult != null) {
            result.error("busy", "Speech recognition is already running", null)
            return
        }
        pendingResult = result
        pendingLanguage = language
        pendingPrompt = prompt

        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST,
            )
        } else {
            launchRecognizer()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) {
            return
        }
        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            launchRecognizer()
        } else {
            finishWithError("permission", "Microphone permission was denied")
        }
    }

    private fun launchRecognizer() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_CALLING_PACKAGE,
                packageName,
            )
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            pendingLanguage?.takeIf { it.isNotBlank() }?.let {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, it)
            }
            pendingPrompt?.takeIf { it.isNotBlank() }?.let {
                putExtra(RecognizerIntent.EXTRA_PROMPT, it)
            }
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, SPEECH_REQUEST)
        } catch (_: ActivityNotFoundException) {
            finishWithError("unavailable", "No speech recognition app is available")
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SPEECH_REQUEST) {
            return
        }
        if (resultCode == Activity.RESULT_OK) {
            val text = data
                ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                ?.firstOrNull()
            finishWithSuccess(text)
        } else {
            finishWithSuccess(null)
        }
    }

    private fun finishWithSuccess(text: String?) {
        val result = pendingResult
        clearPending()
        result?.success(text)
    }

    private fun finishWithError(code: String, message: String) {
        val result = pendingResult
        clearPending()
        result?.error(code, message, null)
    }

    private fun clearPending() {
        pendingResult = null
        pendingLanguage = null
        pendingPrompt = null
    }

    companion object {
        private const val SPEECH_CHANNEL = "com.xaepudin.lafzi/speech"
        private const val SPEECH_REQUEST = 4217
        private const val PERMISSION_REQUEST = 4218
    }
}
