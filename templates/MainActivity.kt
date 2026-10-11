package com.karaokehub.next

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val AUDIO_CHANNEL = "com.karaokehub.next/audio_engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initEngine" -> result.success(true)
                "loadSong" -> result.success(true)
                "play" -> result.success(true)
                "pause" -> result.success(true)
                "stop" -> result.success(true)
                "setPitch" -> result.success(true)
                "setTempo" -> result.success(true)
                else -> result.notImplemented()
            }
        }
    }
}
