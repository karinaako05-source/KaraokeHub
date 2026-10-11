package com.karaokehub.next

import android.os.Bundle
import android.media.MediaPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.karaokehub.next/audio_engine"
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initEngine" -> {
                    result.success(true)
                }
                "loadSong" -> {
                    val path = call.argument<String>("path")
                    try {
                        mediaPlayer?.release()
                        mediaPlayer = MediaPlayer().apply {
                            if (!path.isNullOrEmpty()) {
                                setDataSource(path)
                                prepare()
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "play" -> {
                    try {
                        mediaPlayer?.start()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "pause" -> {
                    try {
                        mediaPlayer?.pause()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stop" -> {
                    try {
                        mediaPlayer?.stop()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setPitch", "setTempo" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }
}
