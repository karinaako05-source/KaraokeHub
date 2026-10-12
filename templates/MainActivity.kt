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
    private var lastExtractedLyrics: List<Map<String, Any>> = emptyList()
    private var sfSynth: SoundFontSynth? = null
    private var isUsingSfSynth: Boolean = false
    private var soundFontLoadedPath: String? = null

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
        initSoundFont()
    }

    private fun initSoundFont() {
        if (sfSynth != null && sfSynth?.isReady() == true) return
        val candidateSf2 = listOf(
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
        )
        for (p in candidateSf2) {
            try {
                val f = File(p)
                if (f.exists() && f.length() > 0) {
                    val synth = SoundFontSynth()
                    // 1. Try direct C/C++ file load (avoids reading 100MB into Dalvik heap)
                    var ok = synth.initFromFile(f.absolutePath)
                    if (!ok) {
                        try {
                            ok = synth.init(f.readBytes())
                        } catch (_: OutOfMemoryError) {}
                    }
                    if (ok) {
                        sfSynth = synth
                        soundFontLoadedPath = p
                        sfSynth?.onComplete = {
                            runOnUiThread {
                                methodChannel?.invokeMethod("onSongEnded", null)
                            }
                        }
                        break
                    }
                }
            } catch (_: Throwable) {}
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
                                        if (path.endsWith(".mid", true) || path.endsWith(".kar", true)) {
                                            try {
                                                val f = File(path)
                                                if (f.exists()) {
                                                    lastExtractedLyrics = parseMidiLyrics(f.readBytes())
                                                }
                                            } catch (_: Exception) {}
                                        }
                                    }
                                }
                            }
                            methodChannel?.invokeMethod("onLyricsLoaded", lastExtractedLyrics)
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
                                if (sfSynth == null || sfSynth?.isReady() != true) {
                                    initSoundFont()
                                }
                                if (sfSynth != null && sfSynth?.isReady() == true) {
                                    mediaPlayer?.release()
                                    mediaPlayer = null
                                    sfSynth?.loadMidi(midiFile.readBytes())
                                    isUsingSfSynth = true
                                    methodChannel?.invokeMethod("onLyricsLoaded", lastExtractedLyrics)
                                    result.success(true)
                                } else {
                                    isUsingSfSynth = false
                                    mediaPlayer?.release()
                                    mediaPlayer = MediaPlayer().apply {
                                        setDataSource(midiFile.absolutePath)
                                        prepare()
                                        applyPlaybackParams()
                                        setOnCompletionListener {
                                            methodChannel?.invokeMethod("onSongEnded", null)
                                        }
                                    }
                                    methodChannel?.invokeMethod("onLyricsLoaded", lastExtractedLyrics)
                                    result.success(true)
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
                            if (isUsingSfSynth) {
                                sfSynth?.play()
                                result.success(true)
                            } else {
                                mediaPlayer?.start()
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "pause" -> {
                        try {
                            if (isUsingSfSynth) {
                                sfSynth?.pause()
                                result.success(true)
                            } else {
                                mediaPlayer?.pause()
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "stop" -> {
                        try {
                            if (isUsingSfSynth) {
                                sfSynth?.stop()
                                result.success(true)
                            } else {
                                mediaPlayer?.stop()
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "seekTo" -> {
                        val positionMs = call.argument<Int>("positionMs") ?: 0
                        try {
                            if (isUsingSfSynth) {
                                sfSynth?.seekMs(positionMs)
                                result.success(true)
                            } else {
                                mediaPlayer?.seekTo(positionMs)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "getPosition" -> {
                        try {
                            if (isUsingSfSynth) {
                                result.success(sfSynth?.currentMs() ?: 0)
                            } else {
                                result.success(mediaPlayer?.currentPosition ?: 0)
                            }
                        } catch (e: Exception) {
                            result.success(0)
                        }
                    }
                    "getDuration" -> {
                        try {
                            if (isUsingSfSynth) {
                                result.success(sfSynth?.durationMs() ?: 0)
                            } else {
                                result.success(mediaPlayer?.duration ?: 0)
                            }
                        } catch (e: Exception) {
                            result.success(0)
                        }
                    }
                    "getSynthStatus" -> {
                        result.success(mapOf(
                            "soundfontActive" to (sfSynth?.isReady() == true),
                            "soundfontPath" to (soundFontLoadedPath ?: "Android Native Sonivox Synth")
                        ))
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
                    "getLyrics" -> {
                        result.success(lastExtractedLyrics)
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
            try {
                lastExtractedLyrics = parseMidiLyrics(midiBytes)
            } catch (_: Exception) {
                lastExtractedLyrics = emptyList()
            }
            val outFile = File(cacheDir, "current_song.mid")
            outFile.writeBytes(midiBytes)
            return outFile
        } else {
            // Already standard MIDI or audio
            try {
                lastExtractedLyrics = parseMidiLyrics(chunk)
            } catch (_: Exception) {
                lastExtractedLyrics = emptyList()
            }
            val outFile = File(cacheDir, "current_song.mid")
            outFile.writeBytes(chunk)
            return outFile
        }
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

                if (vocalMarkerRegex.containsMatchIn(rawPart)) {
                    val cleanPart = rawPart.replace(vocalMarkerRegex, "")
                    if (cleanPart.isNotEmpty()) {
                        currentSyllables.add(SyllableToken(startMs = tMs, endMs = tMs + 500L, text = cleanPart))
                    }
                } else if (!metaHeaderRegex.containsMatchIn(rawPart) && !rawPart.startsWith("SJM", true)) {
                    currentSyllables.add(SyllableToken(startMs = tMs, endMs = tMs + 500L, text = rawPart))
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
