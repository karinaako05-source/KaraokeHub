// Native SoundFont synth bridge for Pinoy Videoke.
//
// Uses two public-domain single-header libraries by Bernhard Schelling:
//   tsf.h  (TinySoundFont)   -> renders audio from a .sf2 soundfont
//   tml.h  (TinyMidiLoader)  -> parses Standard MIDI files
//
// !!! You must add tsf.h and tml.h into this same folder (app/src/main/cpp).
//     See README_SOUNDFONT.md for the exact download links.

#include <jni.h>
#include <cstdlib>
#include <cstring>
#include <android/log.h>

#define TSF_IMPLEMENTATION
#include "tsf.h"
#define TML_IMPLEMENTATION
#include "tml.h"

#define LOG_TAG "SFSynth"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

static tsf* g_tsf = nullptr;
static tml_message* g_head = nullptr;   // base pointer (owns memory)
static tml_message* g_cursor = nullptr; // current playback position
static double g_msPlayed = 0.0;
static double g_totalMs = 0.0;
static int g_sampleRate = 44100;

static void applyMessage(tml_message* m) {
    switch (m->type) {
        case TML_PROGRAM_CHANGE:
            tsf_channel_set_presetnumber(g_tsf, m->channel, m->program, (m->channel == 9));
            break;
        case TML_NOTE_ON:
            tsf_channel_note_on(g_tsf, m->channel, m->key, m->velocity / 127.0f);
            break;
        case TML_NOTE_OFF:
            tsf_channel_note_off(g_tsf, m->channel, m->key);
            break;
        case TML_PITCH_BEND:
            tsf_channel_set_pitchwheel(g_tsf, m->channel, m->pitch_bend);
            break;
        case TML_CONTROL_CHANGE:
            tsf_channel_midi_control(g_tsf, m->channel, m->control, m->control_value);
            break;
        default:
            break;
    }
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_karaokehub_next_SoundFontSynth_nativeInit(JNIEnv* env, jobject, jbyteArray sf2, jint sampleRate) {
    if (g_tsf) { tsf_close(g_tsf); g_tsf = nullptr; }
    jsize len = env->GetArrayLength(sf2);
    jbyte* buf = env->GetByteArrayElements(sf2, nullptr);
    g_tsf = tsf_load_memory(buf, (int) len);
    env->ReleaseByteArrayElements(sf2, buf, JNI_ABORT);
    if (!g_tsf) { LOGI("tsf_load_memory failed"); return JNI_FALSE; }
    g_sampleRate = sampleRate;
    // Channel 10 (index 9) is the drum channel in General MIDI.
    tsf_channel_set_bank_preset(g_tsf, 9, 128, 0);
    tsf_set_output(g_tsf, TSF_STEREO_INTERLEAVED, sampleRate, 0.0f);
    return JNI_TRUE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_karaokehub_next_SoundFontSynth_nativeInitFromFile(JNIEnv* env, jobject, jstring filePath, jint sampleRate) {
    if (g_tsf) { tsf_close(g_tsf); g_tsf = nullptr; }
    const char* pathStr = env->GetStringUTFChars(filePath, nullptr);
    LOGI("tsf_load_filename loading from: %s", pathStr);
    g_tsf = tsf_load_filename(pathStr);
    env->ReleaseStringUTFChars(filePath, pathStr);
    if (!g_tsf) {
        LOGI("tsf_load_filename failed");
        return JNI_FALSE;
    }
    LOGI("tsf_load_filename success! Presets loaded: %d", tsf_get_presetcount(g_tsf));
    g_sampleRate = sampleRate;
    tsf_channel_set_bank_preset(g_tsf, 9, 128, 0);
    tsf_set_output(g_tsf, TSF_STEREO_INTERLEAVED, sampleRate, 0.0f);
    return JNI_TRUE;
}

extern "C" JNIEXPORT jdouble JNICALL
Java_com_karaokehub_next_SoundFontSynth_nativeLoadMidi(JNIEnv* env, jobject, jbyteArray midi) {
    if (g_head) { tml_free(g_head); g_head = nullptr; }
    jsize len = env->GetArrayLength(midi);
    jbyte* buf = env->GetByteArrayElements(midi, nullptr);
    g_head = tml_load_memory(buf, (int) len);
    env->ReleaseByteArrayElements(midi, buf, JNI_ABORT);
    g_cursor = g_head;
    g_msPlayed = 0.0;
    g_totalMs = 0.0;
    for (tml_message* m = g_head; m; m = m->next) g_totalMs = m->time;
    if (g_tsf) tsf_note_off_all(g_tsf);
    return g_totalMs;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_karaokehub_next_SoundFontSynth_nativeRender(JNIEnv* env, jobject, jshortArray out, jint frames) {
    if (!g_tsf) return 0;
    jshort* outBuf = env->GetShortArrayElements(out, nullptr);
    int rendered = 0;
    while (rendered < frames) {
        int block = frames - rendered;
        if (block > 256) block = 256;
        double targetMs = g_msPlayed + block * 1000.0 / g_sampleRate;
        while (g_cursor && g_cursor->time <= targetMs) {
            applyMessage(g_cursor);
            g_cursor = g_cursor->next;
        }
        tsf_render_short(g_tsf, outBuf + rendered * 2, block, 0);
        rendered += block;
        g_msPlayed = targetMs;
        if (!g_cursor && g_msPlayed > g_totalMs + 1500.0) break; // song + short tail done
    }
    env->ReleaseShortArrayElements(out, outBuf, 0);
    // When finished, a subsequent call returns 0 (nothing left to render).
    if (!g_cursor && g_msPlayed > g_totalMs + 1500.0 && rendered == 0) return 0;
    return rendered;
}

extern "C" JNIEXPORT void JNICALL
Java_com_karaokehub_next_SoundFontSynth_nativeSeek(JNIEnv*, jobject, jint ms) {
    if (!g_tsf) return;
    tsf_note_off_all(g_tsf);
    g_cursor = g_head;
    double target = (double) (ms < 0 ? 0 : ms);
    // Fast-forward: apply program/control/pitch state but skip note-ons before target.
    while (g_cursor && g_cursor->time < target) {
        if (g_cursor->type != TML_NOTE_ON) applyMessage(g_cursor);
        g_cursor = g_cursor->next;
    }
    g_msPlayed = target;
}

extern "C" JNIEXPORT void JNICALL
Java_com_karaokehub_next_SoundFontSynth_nativeRelease(JNIEnv*, jobject) {
    if (g_head) { tml_free(g_head); g_head = nullptr; g_cursor = nullptr; }
    if (g_tsf) { tsf_close(g_tsf); g_tsf = nullptr; }
}
