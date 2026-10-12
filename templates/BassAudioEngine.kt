package com.karaokehub.next

import android.content.Context
import com.un4seen.bass.BASS
import com.un4seen.bass.BASSMIDI
import com.un4seen.bass.BASS_FX
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class BassAudioEngine(private val context: Context) {
    private var streamHandle: Int = 0
    private var fontHandle: Int = 0
    private val isInitialized = AtomicBoolean(false)
    private var masterVolume = 1.0f
    private var currentKeyOffset = 0
    private var currentTempoRate = 1.0f
    private var reverb = 1.0f
    private var chorus = 1.0f
    private var sampleRate = 44100
    private var polyphony = 512
    private val eqHandles = IntArray(10)
    private var currentFontPath: String? = null
    private var syncEndHandle: Int = 0

    // Keep strong reference to prevent native callback garbage collection
    private val endSyncProc = BASS.SYNCPROC { _, _, _, _ ->
        onSongEnded?.invoke()
    }

    var onSongEnded: (() -> Unit)? = null

    init {
        initBass()
    }

    fun initBass(): Boolean {
        if (!isInitialized.get()) {
            try {
                if (BASS.BASS_Init(-1, sampleRate, 0) || BASS.BASS_ErrorGetCode() == 14) {
                    BASS.BASS_PluginLoad("libbassmidi.so", 0)
                    BASS.BASS_PluginLoad("libbass_fx.so", 0)
                    BASS.BASS_Start()
                    isInitialized.set(true)
                }
            } catch (t: Throwable) {
                t.printStackTrace()
            }
        }
        return isInitialized.get()
    }

    fun isReady(): Boolean = isInitialized.get() && fontHandle != 0

    fun getLoadedFontPath(): String? = currentFontPath

    fun loadSoundFont(path: String): Boolean {
        if (!isInitialized.get()) {
            if (!initBass()) return false
        }
        val file = File(path)
        if (!file.exists() || file.length() <= 0L) return false

        val loaded = BASSMIDI.BASS_MIDI_FontInit(path, 0)
        if (loaded == 0) return false

        val oldFont = fontHandle
        fontHandle = loaded
        currentFontPath = path

        if (streamHandle != 0) {
            val fonts = arrayOf(
                BASSMIDI.BASS_MIDI_FONT().apply { font = fontHandle; preset = -1; bank = 0 },
                BASSMIDI.BASS_MIDI_FONT().apply { font = fontHandle; preset = -1; bank = 128 }
            )
            BASSMIDI.BASS_MIDI_StreamSetFonts(streamHandle, fonts, fonts.size)
        }

        if (oldFont != 0) {
            BASSMIDI.BASS_MIDI_FontFree(oldFont)
        }
        return true
    }

    fun loadMidi(midiBytes: ByteArray): Boolean {
        stop()
        if (!isInitialized.get()) {
            if (!initBass()) return false
        }

        return try {
            val tempFile = File(context.cacheDir, "current_midi_stream.mid")
            tempFile.writeBytes(midiBytes)

            // Flags: 0x801100 matching NativeMidiStreamPolicy
            streamHandle = BASSMIDI.BASS_MIDI_StreamCreateFile(
                tempFile.absolutePath, 0L, 0L,
                0x801100,
                sampleRate
            )

            if (streamHandle == 0) {
                // Fallback to default flags if specialized flags fail
                streamHandle = BASSMIDI.BASS_MIDI_StreamCreateFile(
                    tempFile.absolutePath, 0L, 0L,
                    0,
                    sampleRate
                )
            }

            if (streamHandle == 0) return false

            // Configure 128 MIDI channels
            BASS.BASS_ChannelSetAttribute(streamHandle, BASSMIDI.BASS_ATTRIB_MIDI_CHANS, 128f)

            // Attach active SoundFont (bank 0 for instruments, bank 128 for drum kits)
            if (fontHandle != 0) {
                val fonts = arrayOf(
                    BASSMIDI.BASS_MIDI_FONT().apply { font = fontHandle; preset = -1; bank = 0 },
                    BASSMIDI.BASS_MIDI_FONT().apply { font = fontHandle; preset = -1; bank = 128 }
                )
                BASSMIDI.BASS_MIDI_StreamSetFonts(streamHandle, fonts, fonts.size)
            }

            // Set 512 polyphony voices
            BASS.BASS_ChannelSetAttribute(streamHandle, BASS.BASS_ATTRIB_MIDI_VOICES, polyphony.toFloat())

            // Spatial Reverb & Chorus
            BASS.BASS_ChannelSetAttribute(streamHandle, BASSMIDI.BASS_ATTRIB_MIDI_REVERB, reverb)
            BASS.BASS_ChannelSetAttribute(streamHandle, 0x12012, chorus)

            // Setup 10-Band Peaking Parametric Equalizer
            setupEqualizer()

            // Apply current transpose and tempo settings
            applyTranspose()
            applySpeed()

            // Master Volume
            BASS.BASS_ChannelSetAttribute(streamHandle, BASS.BASS_ATTRIB_VOL, masterVolume)

            // Register completion listener via BASS_SYNC_END
            syncEndHandle = BASS.BASS_ChannelSetSync(
                streamHandle,
                BASS.BASS_SYNC_END,
                0L,
                endSyncProc,
                null
            )

            true
        } catch (t: Throwable) {
            t.printStackTrace()
            false
        }
    }

    private fun setupEqualizer() {
        if (streamHandle == 0) return
        val centers = floatArrayOf(31.25f, 62.5f, 125f, 250f, 500f, 1000f, 2000f, 4000f, 8000f, 16000f)
        for (i in 0..9) {
            val fx = BASS.BASS_ChannelSetFX(streamHandle, BASS_FX.BASS_FX_BFX_PEAKEQ, i)
            eqHandles[i] = fx
            if (fx != 0) {
                BASS.BASS_FXSetParameters(fx, BASS_FX.BASS_BFX_PEAKEQ().apply {
                    lBand = 0
                    fBandwidth = 1.0f
                    fQ = 0.0f
                    fCenter = centers[i]
                    fGain = 0.0f
                    lChannel = -1
                })
            }
        }
    }

    fun play(): Boolean {
        if (streamHandle != 0) {
            return BASS.BASS_ChannelPlay(streamHandle, false)
        }
        return false
    }

    fun pause() {
        if (streamHandle != 0) {
            BASS.BASS_ChannelPause(streamHandle)
        }
    }

    fun stop() {
        pause()
        if (streamHandle != 0) {
            java.util.Arrays.fill(eqHandles, 0)
            BASS.BASS_StreamFree(streamHandle)
            streamHandle = 0
        }
    }

    fun seekTo(positionMs: Long) {
        if (streamHandle != 0) {
            val bytes = BASS.BASS_ChannelSeconds2Bytes(streamHandle, positionMs / 1000.0)
            BASS.BASS_ChannelSetPosition(streamHandle, bytes, 0)
        }
    }

    fun getPositionMs(): Long {
        if (streamHandle != 0) {
            val bytes = BASS.BASS_ChannelGetPosition(streamHandle, 0)
            if (bytes >= 0) {
                val sec = BASS.BASS_ChannelBytes2Seconds(streamHandle, bytes)
                return (sec * 1000.0).toLong()
            }
        }
        return 0L
    }

    fun getDurationMs(): Long {
        if (streamHandle != 0) {
            val bytes = BASS.BASS_ChannelGetLength(streamHandle, 0)
            if (bytes > 0) {
                val sec = BASS.BASS_ChannelBytes2Seconds(streamHandle, bytes)
                return (sec * 1000.0).toLong()
            }
        }
        return 0L
    }

    fun isPlaying(): Boolean {
        return streamHandle != 0 && BASS.BASS_ChannelIsActive(streamHandle) == 1
    }

    fun setKeyOffset(semitones: Int) {
        currentKeyOffset = semitones.coerceIn(-12, 12)
        applyTranspose()
    }

    private fun applyTranspose() {
        if (streamHandle != 0) {
            for (ch in 0 until 16) {
                if (ch == 9) continue // Never transpose drum channel
                BASSMIDI.BASS_MIDI_StreamEvent(
                    streamHandle,
                    ch,
                    BASSMIDI.MIDI_EVENT_TRANSPOSE,
                    100 + currentKeyOffset
                )
            }
        }
    }

    fun setTempoRate(rate: Float) {
        currentTempoRate = rate.coerceIn(0.5f, 2.0f)
        applySpeed()
    }

    private fun applySpeed() {
        if (streamHandle != 0) {
            BASS.BASS_ChannelSetAttribute(streamHandle, BASSMIDI.BASS_ATTRIB_MIDI_SPEED, currentTempoRate)
        }
    }

    fun release() {
        stop()
        if (fontHandle != 0) {
            BASSMIDI.BASS_MIDI_FontFree(fontHandle)
            fontHandle = 0
        }
        if (isInitialized.get()) {
            BASS.BASS_Free()
            isInitialized.set(false)
        }
    }
}
