package com.karaokehub.next

import android.os.Bundle
import android.os.Build
import android.os.Environment
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.annotation.Keep
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
import java.io.StringWriter
import java.io.PrintWriter
import java.util.Date
import java.util.zip.Inflater
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec
import javax.crypto.spec.IvParameterSpec
import android.util.Log
import com.karaokehub.next.database.NativeLib

@Keep
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.karaokehub.next/audio_engine"
    private var mediaPlayer: MediaPlayer? = null
    private var sfxPlayer: MediaPlayer? = null
    private var methodChannel: MethodChannel? = null
    private var currentPitch: Float = 1.0f
    private var currentTempo: Float = 1.0f
    private var lastExtractedLyrics: List<Map<String, Any>> = emptyList()
    private var bassEngine: BassAudioEngine? = null
    private var isUsingBassEngine: Boolean = false
    private var soundFontLoadedPath: String? = null
    private var playbackSession: Int = 0
    private var mediaVolume: Float = 1.0f
    private var midiVolume: Float = 1.0f
    private var midiPolyphony: Int = 512
    private var midiReverb: Int = 4
    private var midiChorus: Int = 4

    private fun publishLyrics() {
        methodChannel?.invokeMethod("onLyricsLoaded", mapOf(
            "sessionId" to playbackSession, "lyrics" to lastExtractedLyrics
        ))
    }

    private fun reportCompletion(session: Int) {
        if (session == playbackSession) {
            methodChannel?.invokeMethod("onSongEnded", mapOf("sessionId" to session))
        }
    }

    private fun stopAllPlayback() {
        stopPlaybackWatcher()
        try { bassEngine?.stop() } catch (_: Throwable) {}
        try { mediaPlayer?.release() } catch (_: Throwable) {}
        try { sfxPlayer?.release() } catch (_: Throwable) {}
        mediaPlayer = null
        sfxPlayer = null
        isUsingBassEngine = false
        currentPitch = 1.0f
        currentTempo = 1.0f
        lastExtractedLyrics = emptyList()
        publishLyrics()
    }

    private fun configureBass() {
        bassEngine?.setMasterVolume(midiVolume)
        bassEngine?.setEffects(midiPolyphony, midiReverb, midiChorus)
    }

    private fun prepareMediaPlayer(path: String, session: Int): MediaPlayer {
        val player = MediaPlayer()
        try {
            if (path.startsWith("asset:") || path.startsWith("assets/")) {
                val assetPath = path.removePrefix("asset:")
                val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath)
                assets.openFd(key).use { descriptor ->
                    player.setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                }
            } else {
                player.setDataSource(path)
            }
            player.prepare()
            player.setVolume(mediaVolume, mediaVolume)
            player.setOnCompletionListener { reportCompletion(session) }
            return player
        } catch (error: Throwable) {
            player.release()
            throw error
        }
    }

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

    private val playbackWatcherHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private val playbackWatcherRunnable = object : Runnable {
        override fun run() {
            try {
                if (isUsingBassEngine) {
                    if (bassEngine?.isEnded() == true) {
                        stopPlaybackWatcher()
                        runOnUiThread {
                            reportCompletion(playbackSession)
                        }
                        return
                    }
                }
            } catch (_: Throwable) {}
            playbackWatcherHandler.postDelayed(this, 300)
        }
    }

    private fun startPlaybackWatcher() {
        stopPlaybackWatcher()
        playbackWatcherHandler.postDelayed(playbackWatcherRunnable, 300)
    }

    private fun stopPlaybackWatcher() {
        playbackWatcherHandler.removeCallbacks(playbackWatcherRunnable)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
            Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
                try {
                    val file = File("/sdcard/Download/karaoke_crash.log")
                    val sw = StringWriter()
                    val pw = PrintWriter(sw)
                    throwable.printStackTrace(pw)
                    file.appendText("\n[${Date()}] [JAVA/KOTLIN UNCAUGHT CRASH - ${thread.name}]\n$sw\n----------------------------------------\n")
                } catch (_: Throwable) {}
                defaultHandler?.uncaughtException(thread, throwable)
            }
        } catch (_: Throwable) {}
        promptStoragePermissionIfNeeded()
        initSoundFont()
    }

    override fun onDestroy() {
        stopPlaybackWatcher()
        try { bassEngine?.release() } catch (_: Throwable) {}
        try { mediaPlayer?.release() } catch (_: Throwable) {}
        try { sfxPlayer?.release() } catch (_: Throwable) {}
        bassEngine = null
        mediaPlayer = null
        sfxPlayer = null
        super.onDestroy()
    }

    private fun loadSoundFont(targetPath: String? = null): Boolean {
        if (bassEngine == null) {
            bassEngine = BassAudioEngine(this)
        }
        val engine = bassEngine ?: return false

        val pathsToTry = mutableListOf<String>()
        if (!targetPath.isNullOrEmpty()) {
            pathsToTry.add(targetPath)
        }
        pathsToTry.addAll(listOf(
            "/sdcard/SongHub/sound/TBOSf.sf2",
            "/sdcard/SongHub/sound/Dream_Sam2634_V_0.2.1.6.sf2",
            "/sdcard/SongHub/sound/soundfont.sf2",
            "/sdcard/SongHub/sound/Yamaha FF8 GM.sf2",
            "/sdcard/SongHub/sound/YAMAHA_PSR400-500.sf2",
            "/sdcard/SongHub/sound/Live_Party_SoundFont__Techno_.sf2",
            "/sdcard/SongHub/sound/GeneralUser-GS.sf2",
            "/storage/emulated/0/SongHub/sound/TBOSf.sf2",
            "/storage/emulated/0/SongHub/sound/Dream_Sam2634_V_0.2.1.6.sf2",
            "/storage/emulated/0/SongHub/sound/soundfont.sf2",
            "/storage/emulated/0/SongHub/sound/Yamaha FF8 GM.sf2",
            "/storage/emulated/0/SongHub/sound/YAMAHA_PSR400-500.sf2",
            "/storage/emulated/0/SongHub/sound/Live_Party_SoundFont__Techno_.sf2",
            "/storage/emulated/0/SongHub/sound/GeneralUser-GS.sf2",
            "/sdcard/Download/KaraokeHub/content/sound/soundfont.sf2",
            "/sdcard/Download/KaraokeHub/content/sound/TBOSf.sf2",
            "/sdcard/Download/KaraokeHub/content/sound/Dream_Sam2634_V_0.2.1.6.sf2",
            "/sdcard/Download/karaokehub/content/sound/soundfont.sf2",
            "/storage/emulated/0/Download/KaraokeHub/content/sound/soundfont.sf2",
            "/sdcard/Download/soundfont.sf2",
            "/sdcard/Download/idx/soundfont.sf2",
            "/sdcard/KaraokeHub/soundfont.sf2",
            "/storage/emulated/0/Download/soundfont.sf2",
            "/sdcard/CodeOnTheGoProjects/PinoyVideokeNative/app/build/intermediates/assets/debug/soundfont.sf2"
        ))

        for (p in pathsToTry) {
            try {
                val f = File(p)
                if (f.exists() && f.length() > 0) {
                    if (engine.isReady() && engine.getLoadedFontPath() == f.absolutePath) return true
                    val ok = engine.loadSoundFont(f.absolutePath)
                    if (ok) {
                        soundFontLoadedPath = f.absolutePath
                        return true
                    }
                }
            } catch (_: Throwable) {}
        }
        return false
    }

    private fun initSoundFont() {
        if (bassEngine != null && bassEngine?.isReady() == true) return
        loadSoundFont()
    }

    private fun discoverSoundFonts(): List<Map<String, Any>> {
        val candidateRoots = listOf(
            File("/sdcard"),
            File("/storage/emulated/0"),
            File("/sdcard/SongHub"),
            File("/sdcard/Download"),
            File("/sdcard/KaraokeHub"),
            File("/storage/emulated/0/SongHub"),
            File("/storage/emulated/0/Download")
        )
        val sfFiles = mutableListOf<File>()
        for (root in candidateRoots) {
            if (!root.exists() || !root.isDirectory) continue
            // 1. Root level files
            root.listFiles()?.forEach {
                if (it.isFile && it.extension.equals("sf2", true)) sfFiles.add(it)
            }
            // 2. Direct "sound" folder
            val soundDir = File(root, "sound")
            if (soundDir.exists() && soundDir.isDirectory) {
                soundDir.listFiles()?.forEach {
                    if (it.isFile && it.extension.equals("sf2", true)) sfFiles.add(it)
                }
            }
            // 3. "content/sound"
            val contentSoundDir = File(root, "content/sound")
            if (contentSoundDir.exists() && contentSoundDir.isDirectory) {
                contentSoundDir.listFiles()?.forEach {
                    if (it.isFile && it.extension.equals("sf2", true)) sfFiles.add(it)
                }
            }
        }
        return sfFiles.distinctBy { it.absolutePath }
            .sortedBy { it.name.lowercase() }
            .map {
                mapOf(
                    "name" to it.name,
                    "path" to it.absolutePath,
                    "sizeBytes" to it.length()
                )
            }
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
                        playbackSession = call.argument<Int>("sessionId") ?: 0
                        stopAllPlayback()
                        try {
                            require(!path.isNullOrEmpty()) { "Song path is empty" }
                            if (path.endsWith(".mid", true) || path.endsWith(".kar", true)) {
                                val bytes = if (path.startsWith("asset:") || path.startsWith("assets/")) {
                                    val key = FlutterInjector.instance().flutterLoader()
                                        .getLookupKeyForAsset(path.removePrefix("asset:"))
                                    assets.open(key).use { it.readBytes() }
                                } else File(path).readBytes()
                                lastExtractedLyrics = parseMidiLyrics(bytes)
                            }
                            mediaPlayer = prepareMediaPlayer(path, playbackSession)
                            publishLyrics()
                            result.success(true)
                        } catch (error: Throwable) {
                            Log.e("MainActivity", "Song load failed", error)
                            stopAllPlayback()
                            result.success(false)
                        }
                    }
                    "loadBlobSong" -> {
                        playbackSession = call.argument<Int>("sessionId") ?: 0
                        stopAllPlayback()
                        val passedPath = call.argument<String>("blobPath")
                        val sectorOffset = call.argument<Int>("offset") ?: 0
                        val sectorLength = call.argument<Int>("length") ?: 0
                        try {
                            val candidateBlobs = listOfNotNull(
                                passedPath,
                                "/sdcard/SongHub/idx/shubblob",
                                "/storage/emulated/0/SongHub/idx/shubblob",
                                "/sdcard/SongHub/content/idx/shubblob",
                                "/sdcard/Download/KaraokeHub/content/idx/shubblob",
                                "/sdcard/Download/karaokehub/content/idx/shubblob",
                                "/storage/emulated/0/Download/KaraokeHub/content/idx/shubblob",
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
                                if (bassEngine == null || bassEngine?.isReady() != true) {
                                    initSoundFont()
                                }
                                var ok = false
                                if (bassEngine != null && bassEngine?.isReady() == true) {
                                    try {
                                        mediaPlayer?.release()
                                        mediaPlayer = null
                                        configureBass()
                                        ok = bassEngine!!.loadMidi(midiFile.readBytes())
                                    } catch (t: Throwable) {
                                        Log.e("MainActivity", "BASS loadMidi failed", t)
                                        ok = false
                                    }
                                    if (ok) {
                                        isUsingBassEngine = true
                                        publishLyrics()
                                        result.success(true)
                                        return@setMethodCallHandler
                                    }
                                }
                                isUsingBassEngine = false
                                try {
                                    mediaPlayer?.release()
                                    mediaPlayer = prepareMediaPlayer(midiFile.absolutePath, playbackSession)
                                    publishLyrics()
                                    result.success(true)
                                } catch (e: Exception) {
                                    Log.e("MainActivity", "MediaPlayer fallback failed", e)
                                    mediaPlayer?.release()
                                    mediaPlayer = null
                                    result.success(false)
                                }
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "play" -> {
                        try {
                            val ok = if (isUsingBassEngine) {
                                bassEngine?.play() == true
                            } else {
                                val player = mediaPlayer
                                if (player == null) false else { player.start(); applyPlaybackParams(); true }
                            }
                            if (ok && isUsingBassEngine) startPlaybackWatcher()
                            result.success(ok)
                        } catch (error: Throwable) {
                            Log.e("MainActivity", "Playback start failed", error)
                            result.success(false)
                        }
                    }
                    "pause" -> {
                        stopPlaybackWatcher()
                        try {
                            val ok = if (isUsingBassEngine) bassEngine?.pause() == true
                                else mediaPlayer?.let { it.pause(); true } ?: false
                            result.success(ok)
                        } catch (_: Throwable) { result.success(false) }
                    }
                    "stop" -> {
                        stopAllPlayback()
                        result.success(true)
                    }
                    "seekTo" -> {
                        val positionMs = call.argument<Int>("positionMs") ?: 0
                        try {
                            val ok = if (isUsingBassEngine) {
                                bassEngine?.seekTo(positionMs.toLong()) == true
                            } else mediaPlayer?.let { it.seekTo(positionMs); true } ?: false
                            result.success(ok)
                        } catch (_: Throwable) { result.success(false) }
                    }
                    "getPosition" -> {
                        try {
                            if (isUsingBassEngine) {
                                result.success(bassEngine?.getPositionMs() ?: 0L)
                            } else {
                                result.success(mediaPlayer?.currentPosition ?: 0)
                            }
                        } catch (e: Exception) {
                            result.success(0)
                        }
                    }
                    "getDuration" -> {
                        try {
                            if (isUsingBassEngine) {
                                result.success(bassEngine?.getDurationMs() ?: 0L)
                            } else {
                                result.success(mediaPlayer?.duration ?: 0)
                            }
                        } catch (e: Exception) {
                            result.success(0)
                        }
                    }
                    "getSynthStatus" -> {
                        result.success(mapOf(
                            "soundfontActive" to (bassEngine?.isReady() == true),
                            "soundfontPath" to (soundFontLoadedPath ?: "BASSMIDI Professional Audio Engine")
                        ))
                    }
                    "setSoundFont" -> {
                        val path = call.argument<String>("path")
                        val ok = loadSoundFont(path)
                        result.success(ok)
                    }
                    "getSoundFonts" -> {
                        result.success(discoverSoundFonts())
                    }
                    "applySettings" -> {
                        midiVolume = (call.argument<Double>("midiVolume") ?: 1.0).toFloat().coerceIn(0.0f, 2.0f)
                        // MediaPlayer's volume API is limited to 0..1.
                        mediaVolume = (call.argument<Double>("mediaVolume") ?: 1.0).toFloat().coerceIn(0.0f, 1.0f)
                        midiPolyphony = (call.argument<Int>("polyphony") ?: 512).coerceIn(64, 512)
                        midiReverb = (call.argument<Int>("reverb") ?: 4).coerceIn(0, 4)
                        midiChorus = (call.argument<Int>("chorus") ?: 4).coerceIn(0, 4)
                        configureBass()
                        mediaPlayer?.setVolume(mediaVolume, mediaVolume)
                        result.success(true)
                    }
                    "setPitch" -> {
                        val semitones = call.argument<Int>("semitones") ?: 0
                        if (isUsingBassEngine) {
                            bassEngine?.setKeyOffset(semitones)
                        }
                        currentPitch = Math.pow(2.0, semitones / 12.0).toFloat().coerceIn(0.5f, 2.0f)
                        applyPlaybackParams()
                        result.success(true)
                    }
                    "setTempo" -> {
                        val rate = call.argument<Double>("rate") ?: 1.0
                        if (isUsingBassEngine) {
                            bassEngine?.setTempoRate(rate.toFloat())
                        }
                        currentTempo = rate.toFloat().coerceIn(0.5f, 2.0f)
                        applyPlaybackParams()
                        result.success(true)
                    }
                    "playSfx" -> {
                        val name = call.argument<String>("name")
                        val volume = (call.argument<Double>("volume") ?: 1.0).toFloat().coerceIn(0.0f, 1.0f)
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
                                    setVolume(volume, volume)
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
                    "getLyrics" -> {
                        result.success(mapOf("sessionId" to playbackSession, "lyrics" to lastExtractedLyrics))
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

        if (byteOffset < 0 || byteLength <= 0 || byteOffset + byteLength > blobFile.length()) {
            Log.e("MainActivity", "Slice out of bounds: offset=$byteOffset length=$byteLength blobSize=${blobFile.length()}")
            return null
        }

        val chunk = ByteArray(byteLength.toInt())
        RandomAccessFile(blobFile, "r").use { raf ->
            raf.seek(byteOffset)
            raf.readFully(chunk)
        }

        val isMkmd = chunk.size >= 4 &&
                chunk[0] == 0x4D.toByte() &&
                chunk[1] == 0x4B.toByte() &&
                chunk[2] == 0x4D.toByte() &&
                chunk[3] == 0x44.toByte()
        val isMthd = chunk.size >= 4 &&
                chunk[0] == 'M'.code.toByte() &&
                chunk[1] == 'T'.code.toByte() &&
                chunk[2] == 'h'.code.toByte() &&
                chunk[3] == 'd'.code.toByte()

        var midiBytes: ByteArray? = null
        if (isMkmd || !isMthd) {
            // Native MIDI decryption via libKhNext.so
            try {
                midiBytes = NativeLib.processMidiData(chunk, false)
            } catch (t: Throwable) {
                Log.e("MainActivity", "NativeLib.processMidiData error: ${t.message}", t)
            }
        } else {
            midiBytes = chunk
        }

        // Fallback to AES/Inflater if NativeLib returned null
        if (midiBytes == null && isMkmd && chunk.size >= 13) {
            try {
                val encLen = (chunk[9].toInt() and 0xff) or
                        ((chunk[10].toInt() and 0xff) shl 8) or
                        ((chunk[11].toInt() and 0xff) shl 16) or
                        ((chunk[12].toInt() and 0xff) shl 24)

                val sliceLen = (encLen + 15) and 15.inv()
                val cipherText = ByteArray(sliceLen)
                System.arraycopy(chunk, 13, cipherText, 0, sliceLen.coerceAtMost(chunk.size - 13))

                val keySpec = SecretKeySpec(AES_KEY, "AES")
                val ivSpec = IvParameterSpec(AES_IV)
                val cipher = Cipher.getInstance("AES/CBC/NoPadding")
                cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec)
                val decrypted = cipher.doFinal(cipherText)

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
                midiBytes = bos.toByteArray()
            } catch (e: Throwable) {
                Log.w("MainActivity", "AES fallback decode error: ${e.message}")
            }
        }

        if (midiBytes == null || midiBytes.isEmpty()) {
            Log.e("MainActivity", "Failed to obtain decrypted MIDI for slice offset=$offsetSectors")
            return null
        }

        try {
            lastExtractedLyrics = parseMidiLyrics(midiBytes)
        } catch (_: Exception) {
            lastExtractedLyrics = emptyList()
        }
        val outFile = File(cacheDir, "current_song.mid")
        outFile.writeBytes(midiBytes)
        return outFile
    }

    private fun parseMidiLyrics(midi: ByteArray): List<Map<String, Any>> {
        if (midi.size < 14) return emptyList()
        if (midi[0] != 'M'.code.toByte() || midi[1] != 'T'.code.toByte() ||
            midi[2] != 'h'.code.toByte() || midi[3] != 'd'.code.toByte()) {
            return emptyList()
        }

        val numTracks = ((midi[10].toInt() and 0xff) shl 8) or (midi[11].toInt() and 0xff)
        val rawDivision = ((midi[12].toInt() and 0xff) shl 8) or (midi[13].toInt() and 0xff)
        val ticksPerBeat = if ((rawDivision and 0x8000) == 0) rawDivision else 480

        class TempoPoint(val tick: Long, val usPerBeat: Long)
        class RawEvent(val tick: Long, val type: Int, val text: String)

        val tempoList = mutableListOf<TempoPoint>()
        tempoList.add(TempoPoint(0L, 500000L))
        val rawEvents = mutableListOf<RawEvent>()

        var idx = 14
        for (t in 0 until numTracks) {
            if (idx + 8 > midi.size) break
            val isTrk = (midi[idx] == 'M'.code.toByte() && midi[idx+1] == 'T'.code.toByte() &&
                         midi[idx+2] == 'r'.code.toByte() && midi[idx+3] == 'k'.code.toByte())
            val trkLen = ((midi[idx+4].toInt() and 0xff) shl 24) or
                         ((midi[idx+5].toInt() and 0xff) shl 16) or
                         ((midi[idx+6].toInt() and 0xff) shl 8) or
                         (midi[idx+7].toInt() and 0xff)
            idx += 8
            val trkEnd = (idx + trkLen).coerceAtMost(midi.size)
            if (!isTrk) {
                idx = trkEnd
                continue
            }

            var tPos = idx
            var curTick = 0L
            var lastStatus = 0

            while (tPos < trkEnd) {
                // Read varint delta
                var delta = 0L
                while (tPos < trkEnd) {
                    val b = midi[tPos++].toInt() and 0xff
                    delta = (delta shl 7) or (b and 0x7f).toLong()
                    if ((b and 0x80) == 0) break
                }
                curTick += delta
                if (tPos >= trkEnd) break

                var status = midi[tPos].toInt() and 0xff
                if ((status and 0x80) != 0) {
                    tPos++
                    lastStatus = status
                } else {
                    status = lastStatus
                }

                if (status == 0xFF) { // Meta event
                    if (tPos >= trkEnd) break
                    val metaType = midi[tPos++].toInt() and 0xff
                    var metaLen = 0
                    while (tPos < trkEnd) {
                        val b = midi[tPos++].toInt() and 0xff
                        metaLen = (metaLen shl 7) or (b and 0x7f)
                        if ((b and 0x80) == 0) break
                    }
                    val endMeta = (tPos + metaLen).coerceAtMost(trkEnd)
                    val len = endMeta - tPos

                    if (metaType == 0x51 && len >= 3) { // Set Tempo
                        val us = ((midi[tPos].toLong() and 0xff) shl 16) or
                                 ((midi[tPos+1].toLong() and 0xff) shl 8) or
                                 (midi[tPos+2].toLong() and 0xff)
                        tempoList.add(TempoPoint(curTick, us))
                    } else if (metaType == 0x01 || metaType == 0x05) { // Text or Lyric
                        try {
                            val str = String(midi, tPos, len, Charsets.ISO_8859_1)
                            rawEvents.add(RawEvent(curTick, metaType, str))
                        } catch (_: Exception) {}
                    }
                    tPos = endMeta
                } else if ((status and 0xF0) in listOf(0x80, 0x90, 0xA0, 0xB0, 0xE0)) {
                    tPos = (tPos + 2).coerceAtMost(trkEnd)
                } else if ((status and 0xF0) in listOf(0xC0, 0xD0)) {
                    tPos = (tPos + 1).coerceAtMost(trkEnd)
                } else if (status == 0xF0 || status == 0xF7) { // Sysex
                    var sysLen = 0
                    while (tPos < trkEnd) {
                        val b = midi[tPos++].toInt() and 0xff
                        sysLen = (sysLen shl 7) or (b and 0x7f)
                        if ((b and 0x80) == 0) break
                    }
                    tPos = (tPos + sysLen).coerceAtMost(trkEnd)
                }
            }
            idx = trkEnd
        }

        tempoList.sortBy { it.tick }
        rawEvents.sortBy { it.tick }

        fun tickToMs(targetTick: Long): Long {
            var curMs = 0.0
            var prevTick = 0L
            var curTempo = 500000L
            for (tp in tempoList) {
                if (targetTick <= tp.tick) break
                val dt = tp.tick - prevTick
                curMs += (dt * curTempo).toDouble() / (ticksPerBeat * 1000.0)
                prevTick = tp.tick
                curTempo = tp.usPerBeat
            }
            curMs += ((targetTick - prevTick) * curTempo).toDouble() / (ticksPerBeat * 1000.0)
            return curMs.toLong()
        }

        data class SyllableToken(val startMs: Long, val endMs: Long, val text: String)
        data class PendingLine(val tokens: MutableList<SyllableToken>)

        val parsedLines = mutableListOf<PendingLine>()
        var currentSyllables = mutableListOf<SyllableToken>()
        var lastEventMs = 0L

        val hasType5 = rawEvents.any { it.type == 0x05 }
        val eligible = rawEvents.filter { if (hasType5) it.type == 0x05 else it.type == 0x01 }

        val vocalMarkerRegex = Regex("^(?i)(?:@[mwcfv12]|M:|F:|B:|D:)\\s*")
        val metaHeaderRegex = Regex("^(?i)@[a-zA-Z0-9_]+")

        for (ev in eligible) {
            val tMs = tickToMs(ev.tick)
            var str = ev.text.replace("^", "").replace("<", " ")

            if (currentSyllables.isNotEmpty() && (tMs - lastEventMs) > 2800L) {
                parsedLines.add(PendingLine(currentSyllables))
                currentSyllables = mutableListOf()
            }
            lastEventMs = tMs

            val normalized = str.replace("\r", "\n").replace("/", "\n").replace("\\", "\n")
            val parts = normalized.split("\n")

            for (i in parts.indices) {
                if (i > 0) {
                    if (currentSyllables.isNotEmpty()) {
                        parsedLines.add(PendingLine(currentSyllables))
                        currentSyllables = mutableListOf()
                    }
                }
                val rawPart = parts[i].trim('\u0000')
                if (rawPart.isEmpty()) continue

                // Discard pure countdown/beat markers (e.g. '#', '# ', '####') so they don't shift line timings
                val trimmedPart = rawPart.trim()
                if (trimmedPart.isNotEmpty() && trimmedPart.all { it == '#' || it.isWhitespace() }) {
                    continue
                }

                if (vocalMarkerRegex.containsMatchIn(rawPart)) {
                    val cleanPart = rawPart.replace(vocalMarkerRegex, "").replace("#", "").trim()
                    if (cleanPart.isNotEmpty()) {
                        currentSyllables.add(SyllableToken(startMs = tMs, endMs = tMs + 500L, text = cleanPart))
                    }
                } else if (!metaHeaderRegex.containsMatchIn(rawPart) && !rawPart.startsWith("SJM", true)) {
                    val cleanPart = rawPart.replace("#", "")
                    if (cleanPart.isNotEmpty()) {
                        currentSyllables.add(SyllableToken(startMs = tMs, endMs = tMs + 500L, text = cleanPart))
                    }
                }
            }
        }
        if (currentSyllables.isNotEmpty()) {
            parsedLines.add(PendingLine(currentSyllables))
        }

        val resultLines = mutableListOf<Map<String, Any>>()
        for (lineIdx in parsedLines.indices) {
            val pending = parsedLines[lineIdx]
            val resolvedTokens = mutableListOf<Map<String, Any>>()
            val count = pending.tokens.size

            for (tokenIdx in 0 until count) {
                val token = pending.tokens[tokenIdx]
                val nextStartMs = if (tokenIdx + 1 < count) {
                    pending.tokens[tokenIdx + 1].startMs
                } else {
                    parsedLines.getOrNull(lineIdx + 1)?.tokens?.firstOrNull()?.startMs
                }

                val endMs = if (nextStartMs != null && nextStartMs > token.startMs) {
                    Math.min(nextStartMs, token.startMs + 3000L)
                } else {
                    token.startMs + 700L
                }

                resolvedTokens.add(mapOf(
                    "startMs" to token.startMs,
                    "endMs" to endMs,
                    "text" to token.text
                ))
            }

            if (resolvedTokens.isEmpty()) continue

            val fullText = resolvedTokens.joinToString("") { it["text"] as String }.replace("#", "").trim()
            if (fullText.isNotEmpty()) {
                val lineStartMs = resolvedTokens.first()["startMs"] as Long
                val lineEndMs = (resolvedTokens.last()["endMs"] as Long) + 300L
                resultLines.add(mapOf(
                    "timeMs" to lineStartMs,
                    "endMs" to lineEndMs,
                    "text" to fullText,
                    "tokens" to resolvedTokens
                ))
            }
        }

        return resultLines
    }

    private fun applyPlaybackParams() {
        try {
            if (mediaPlayer != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                if (mediaPlayer?.isPlaying != true) return
                val params = mediaPlayer?.playbackParams ?: PlaybackParams()
                params.pitch = currentPitch
                params.speed = currentTempo
                mediaPlayer?.playbackParams = params
            }
        } catch (_: Exception) {}
    }
}
