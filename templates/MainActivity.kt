package com.karaokehub.next

import android.os.Bundle
import android.os.Build
import android.os.Environment
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.media.MediaPlayer
import android.media.PlaybackParams
import android.content.res.AssetFileDescriptor
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.RandomAccessFile
import java.io.ByteArrayOutputStream
import java.util.zip.Inflater
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec
import javax.crypto.spec.IvParameterSpec

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.karaokehub.next/audio_engine"
    private var mediaPlayer: MediaPlayer? = null
    private var sfxPlayer: MediaPlayer? = null
    private var methodChannel: MethodChannel? = null
    private var currentPitch: Float = 1.0f
    private var currentTempo: Float = 1.0f

    // 256-bit AES Key and 128-bit IV for MKMD slices from shubblob
    private val AES_KEY = byteArrayOf(
        0xb3.toByte(), 0x02.toByte(), 0xd5.toByte(), 0x6b.toByte(),
        0x35.toByte(), 0x89.toByte(), 0x0a.toByte(), 0xa2.toByte(),
        0x56.toByte(), 0xe6.toByte(), 0xf7.toByte(), 0x9e.toByte(),
        0xe2.toByte(), 0x95.toByte(), 0x4c.toByte(), 0x1b.toByte(),
        0x86.toByte(), 0x82.toByte(), 0xb1.toByte(), 0xfc.toByte(),
        0xf2.toByte(), 0x8c.toByte(), 0xa6.toByte(), 0xe0.toByte(),
        0x40.toByte(), 0x9e.toByte(), 0xb9.toByte(), 0x19.toByte(),
        0xea.toByte(), 0xe2.toByte(), 0x3d.toByte(), 0xea.toByte()
    )
    private val AES_IV = byteArrayOf(
        0xe4.toByte(), 0xf8.toByte(), 0xb2.toByte(), 0xc9.toByte(),
        0xe1.toByte(), 0xa7.toByte(), 0xd6.toByte(), 0xf5.toByte(),
        0x30.toByte(), 0xe4.toByte(), 0xb8.toByte(), 0xa2.toByte(),
        0xc9.toByte(), 0xf1.toByte(), 0xd3.toByte(), 0xe5.toByte()
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        promptStoragePermissionIfNeeded()
    }

    private fun promptStoragePermissionIfNeeded() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (!Environment.isExternalStorageManager()) {
                    val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                }
            } else {
                if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(
                            android.Manifest.permission.READ_EXTERNAL_STORAGE,
                            android.Manifest.permission.WRITE_EXTERNAL_STORAGE
                        ),
                        101
                    )
                }
            }
        } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkStoragePermission" -> {
                        val hasPerm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            Environment.isExternalStorageManager()
                        } else {
                            ContextCompat.checkSelfPermission(
                                this@MainActivity,
                                android.Manifest.permission.READ_EXTERNAL_STORAGE
                            ) == PackageManager.PERMISSION_GRANTED
                        }
                        result.success(hasPerm)
                    }
                    "requestStoragePermission" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                            } else {
                                ActivityCompat.requestPermissions(
                                    this@MainActivity,
                                    arrayOf(
                                        android.Manifest.permission.READ_EXTERNAL_STORAGE,
                                        android.Manifest.permission.WRITE_EXTERNAL_STORAGE
                                    ),
                                    101
                                )
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                                startActivity(intent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "initEngine" -> {
                        result.success(true)
                    }
                    "loadSong" -> {
                        val path = call.argument<String>("path")
                        try {
                            mediaPlayer?.release()
                            mediaPlayer = MediaPlayer().apply {
                                if (!path.isNullOrEmpty()) {
                                    if (path.startsWith("asset:") || path.startsWith("assets/")) {
                                        val assetPath = path.removePrefix("asset:")
                                        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath)
                                        val afd: AssetFileDescriptor = assets.openFd(key)
                                        setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                                        afd.close()
                                    } else {
                                        setDataSource(path)
                                    }
                                    prepare()
                                    applyPlaybackParams()
                                    setOnCompletionListener {
                                        methodChannel?.invokeMethod("onSongEnded", null)
                                    }
                                }
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "loadBlobSong" -> {
                        val passedPath = call.argument<String>("blobPath")
                        val sectorOffset = call.argument<Int>("offset") ?: 0
                        val sectorLength = call.argument<Int>("length") ?: 0
                        try {
                            val candidateBlobs = listOfNotNull(
                                passedPath,
                                "/sdcard/Download/idx/shubblob",
                                "/sdcard/Download/shubblob",
                                "/storage/emulated/0/Download/idx/shubblob",
                                "/storage/emulated/0/Download/shubblob",
                                "/sdcard/KaraokeHub/karaokehub-private-020/content/idx/shubblob",
                                "/sdcard/KaraokeHub/idx/shubblob",
                                "/storage/emulated/0/KaraokeHub/karaokehub-private-020/content/idx/shubblob",
                                "/storage/emulated/0/KaraokeHub/idx/shubblob"
                            )
                            val resolvedBlobPath = candidateBlobs.firstOrNull { File(it).let { f -> f.exists() && f.length() > 0 } }
                                ?: passedPath ?: "/sdcard/Download/idx/shubblob"

                            val midiFile = extractAndDecryptSlice(resolvedBlobPath, sectorOffset, sectorLength)
                            if (midiFile != null && midiFile.exists()) {
                                mediaPlayer?.release()
                                mediaPlayer = MediaPlayer().apply {
                                    setDataSource(midiFile.absolutePath)
                                    prepare()
                                    applyPlaybackParams()
                                    setOnCompletionListener {
                                        methodChannel?.invokeMethod("onSongEnded", null)
                                    }
                                }
                                result.success(true)
                            } else {
                                result.success(false)
                            }
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
                    "seekTo" -> {
                        val positionMs = call.argument<Int>("positionMs") ?: 0
                        try {
                            mediaPlayer?.seekTo(positionMs)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "getPosition" -> {
                        try {
                            result.success(mediaPlayer?.currentPosition ?: 0)
                        } catch (e: Exception) {
                            result.success(0)
                        }
                    }
                    "getDuration" -> {
                        try {
                            result.success(mediaPlayer?.duration ?: 0)
                        } catch (e: Exception) {
                            result.success(0)
                        }
                    }
                    "setPitch" -> {
                        val semitones = call.argument<Int>("semitones") ?: 0
                        currentPitch = Math.pow(2.0, semitones / 12.0).toFloat().coerceIn(0.5f, 2.0f)
                        applyPlaybackParams()
                        result.success(true)
                    }
                    "setTempo" -> {
                        val rate = call.argument<Double>("rate") ?: 1.0
                        currentTempo = rate.toFloat().coerceIn(0.5f, 2.0f)
                        applyPlaybackParams()
                        result.success(true)
                    }
                    "playSfx" -> {
                        val name = call.argument<String>("name")
                        try {
                            if (!name.isNullOrEmpty()) {
                                val assetPath = "assets/audio/sfx/$name.mp3"
                                val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath)
                                val afd: AssetFileDescriptor = assets.openFd(key)
                                sfxPlayer?.release()
                                sfxPlayer = MediaPlayer().apply {
                                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                                    afd.close()
                                    prepare()
                                    start()
                                    setOnCompletionListener {
                                        it.release()
                                        if (sfxPlayer == it) sfxPlayer = null
                                    }
                                }
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun extractAndDecryptSlice(blobPath: String, offsetSectors: Int, lengthSectors: Int): File? {
        val blobFile = File(blobPath)
        if (!blobFile.exists()) return null

        val sectorSize = 2048L
        val byteOffset = offsetSectors.toLong() * sectorSize
        val byteLength = lengthSectors.toLong() * sectorSize

        val chunk = ByteArray(byteLength.toInt())
        RandomAccessFile(blobFile, "r").use { raf ->
            raf.seek(byteOffset)
            raf.readFully(chunk)
        }

        // Check if starts with MKMD
        if (chunk.size >= 13 &&
            chunk[0] == 'M'.code.toByte() &&
            chunk[1] == 'K'.code.toByte() &&
            chunk[2] == 'M'.code.toByte() &&
            chunk[3] == 'D'.code.toByte()) {

            val encLen = (chunk[9].toInt() and 0xff) or
                         ((chunk[10].toInt() and 0xff) shl 8) or
                         ((chunk[11].toInt() and 0xff) shl 16) or
                         ((chunk[12].toInt() and 0xff) shl 24)

            val sliceLen = (encLen + 15) and 15.inv()
            val cipherText = ByteArray(sliceLen)
            System.arraycopy(chunk, 13, cipherText, 0, sliceLen.coerceAtMost(chunk.size - 13))

            // AES-256-CBC Decryption
            val keySpec = SecretKeySpec(AES_KEY, "AES")
            val ivSpec = IvParameterSpec(AES_IV)
            val cipher = Cipher.getInstance("AES/CBC/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec)
            val decrypted = cipher.doFinal(cipherText)

            // Raw Deflate Inflate
            val inflater = Inflater(true)
            inflater.setInput(decrypted, 0, encLen.coerceAtMost(decrypted.size))

            val bos = ByteArrayOutputStream()
            val buffer = ByteArray(4096)
            while (!inflater.finished()) {
                val count = inflater.inflate(buffer)
                if (count == 0 && inflater.needsInput()) break
                bos.write(buffer, 0, count)
            }
            inflater.end()

            val midiBytes = bos.toByteArray()
            val outFile = File(cacheDir, "current_song.mid")
            outFile.writeBytes(midiBytes)
            return outFile
        } else {
            // Already standard MIDI or audio
            val outFile = File(cacheDir, "current_song.mid")
            outFile.writeBytes(chunk)
            return outFile
        }
    }

    private fun applyPlaybackParams() {
        try {
            if (mediaPlayer != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val params = mediaPlayer?.playbackParams ?: PlaybackParams()
                params.pitch = currentPitch
                params.speed = currentTempo
                mediaPlayer?.playbackParams = params
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        mediaPlayer = null
        sfxPlayer?.release()
        sfxPlayer = null
        super.onDestroy()
    }
}
