package com.karaokehub.next

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val AUDIO_CHANNEL = "com.karaokehub.next/audio_engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initEngine" -> {
                    // Placeholder for BASS / BASSMIDI initialization
                    result.success(true)
                }
                "loadSong" -> {
                    val path = call.argument<String>("path")
                    result.success(true)
                }
                "play" -> {
                    result.success(true)
                }
                "pause" -> {
                    result.success(true)
                }
                "stop" -> {
                    result.success(true)
                }
                "setPitch" -> {
                    val semitones = call.argument<Int>("semitones") ?: 0
                    result.success(true)
                }
                "setTempo" -> {
                    val rate = call.argument<Double>("rate") ?: 1.0
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
