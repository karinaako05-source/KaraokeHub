package com.karaokehub.next

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import kotlin.concurrent.thread

/**
 * Real SoundFont (.sf2) playback via native TinySoundFont + TinyMidiLoader.
 * Renders PCM on a background thread and streams it to an AudioTrack.
 *
 * Requires the native library `libsfsynth` (see app/src/main/cpp). If the
 * library or soundfont is missing, [init] returns false and callers should
 * fall back to the built-in MediaPlayer synth.
 */
class SoundFontSynth(private val sampleRate: Int = 44100) {

    companion object {
        @Volatile private var libLoaded = false
        fun tryLoad(): Boolean {
            if (libLoaded) return true
            return try { System.loadLibrary("sfsynth"); libLoaded = true; true }
            catch (t: Throwable) { false }
        }
    }

    private external fun nativeInit(sf2: ByteArray, sampleRate: Int): Boolean
    private external fun nativeInitFromFile(filePath: String, sampleRate: Int): Boolean
    private external fun nativeLoadMidi(midi: ByteArray): Double
    private external fun nativeRender(out: ShortArray, frames: Int): Int
    private external fun nativeSeek(ms: Int)
    private external fun nativeRelease()

    private var inited = false
    private var track: AudioTrack? = null
    private var worker: Thread? = null
    @Volatile private var playing = false
    @Volatile private var quit = false
    @Volatile private var basePosMs = 0
    private var totalMs = 0.0

    private val framesPerChunk = 2048
    private val chunk = ShortArray(framesPerChunk * 2)

    var onComplete: (() -> Unit)? = null

    fun init(sf2: ByteArray): Boolean {
        inited = tryLoad() && try { nativeInit(sf2, sampleRate) } catch (_: Throwable) { false }
        return inited
    }

    fun initFromFile(filePath: String): Boolean {
        inited = tryLoad() && try { nativeInitFromFile(filePath, sampleRate) } catch (_: Throwable) { false }
        return inited
    }

    fun isReady() = inited
    fun playingNow() = playing
    fun durationMs(): Int = totalMs.toInt()

    fun loadMidi(midi: ByteArray) {
        stopWorker()
        totalMs = try { nativeLoadMidi(midi) } catch (_: Throwable) { 0.0 }
        setupTrack()
        basePosMs = 0
    }

    fun play() {
        val t = track ?: return
        if (worker != null) {
            playing = true
            try { t.play() } catch (_: Exception) {}
            return
        }
        playing = true; quit = false
        try { t.play() } catch (_: Exception) {}
        worker = thread(name = "sfsynth", isDaemon = true) {
            while (!quit) {
                if (!playing) { try { Thread.sleep(15) } catch (_: Exception) {}; continue }
                val n = try { nativeRender(chunk, framesPerChunk) } catch (_: Throwable) { 0 }
                if (n <= 0) {
                    playing = false
                    val cb = onComplete
                    worker = null
                    cb?.invoke()
                    break
                }
                var off = 0; var remain = n * 2
                while (remain > 0 && !quit && playing) {
                    val w = try { t.write(chunk, off, remain) } catch (_: Exception) { -1 }
                    if (w <= 0) break
                    off += w; remain -= w
                }
            }
        }
    }

    fun pause() {
        playing = false
        try { track?.pause() } catch (_: Exception) {}
    }

    fun seekMs(ms: Int) {
        val t = track ?: return
        val wasPlaying = playing
        playing = false
        try { t.pause(); t.flush() } catch (_: Exception) {}
        try { nativeSeek(ms.coerceAtLeast(0)) } catch (_: Throwable) {}
        basePosMs = ms.coerceAtLeast(0)
        if (wasPlaying) { playing = true; try { t.play() } catch (_: Exception) {} }
    }

    fun stop() {
        seekMs(0)
        pause()
    }

    fun currentMs(): Int {
        val t = track ?: return basePosMs
        return try {
            val frames = t.playbackHeadPosition.toLong() and 0xFFFFFFFFL
            basePosMs + (frames * 1000 / sampleRate).toInt()
        } catch (_: Exception) { basePosMs }
    }

    private fun setupTrack() {
        releaseTrack()
        val min = AudioTrack.getMinBufferSize(
            sampleRate, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_16BIT
        ).coerceAtLeast(framesPerChunk * 2 * 4)
        track = AudioTrack(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build(),
            AudioFormat.Builder()
                .setSampleRate(sampleRate)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                .build(),
            min, AudioTrack.MODE_STREAM, AudioManager.AUDIO_SESSION_ID_GENERATE
        )
    }

    private fun stopWorker() {
        quit = true; playing = false
        try { worker?.join(300) } catch (_: Exception) {}
        worker = null; quit = false
    }

    private fun releaseTrack() {
        try { track?.stop() } catch (_: Exception) {}
        try { track?.release() } catch (_: Exception) {}
        track = null
    }

    fun release() {
        stopWorker()
        releaseTrack()
        try { nativeRelease() } catch (_: Throwable) {}
        inited = false
    }
}
