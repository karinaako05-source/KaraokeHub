package com.un4seen.bass;

public class BASS {
    static {
        try { System.loadLibrary("bass"); } catch (Throwable t) {}
    }

    public static class Asset {
        public Asset() {}
        public java.lang.String file;
        public android.content.res.AssetManager manager;
    }

    public static class BASS_3DVECTOR {
        public BASS_3DVECTOR() {}
        public float x;
        public float y;
        public float z;
    }

    public static class BASS_CHANNELINFO {
        public BASS_CHANNELINFO() {}
        public int chans;
        public int ctype;
        public java.lang.String filename;
        public int flags;
        public int freq;
        public int origres;
        public int plugin;
        public int sample;
    }

    public static class BASS_DEVICEINFO {
        public BASS_DEVICEINFO() {}
        public java.lang.String driver;
        public int flags;
        public java.lang.String name;
    }

    public static class BASS_DX8_CHORUS {
        public BASS_DX8_CHORUS() {}
        public float fDelay;
        public float fDepth;
        public float fFeedback;
        public float fFrequency;
        public float fWetDryMix;
        public int lPhase;
        public int lWaveform;
    }

    public static class BASS_DX8_DISTORTION {
        public BASS_DX8_DISTORTION() {}
        public float fEdge;
        public float fGain;
        public float fPostEQBandwidth;
        public float fPostEQCenterFrequency;
        public float fPreLowpassCutoff;
    }

    public static class BASS_DX8_ECHO {
        public BASS_DX8_ECHO() {}
        public float fFeedback;
        public float fLeftDelay;
        public float fRightDelay;
        public float fWetDryMix;
        public boolean lPanDelay;
    }

    public static class BASS_DX8_FLANGER {
        public BASS_DX8_FLANGER() {}
        public float fDelay;
        public float fDepth;
        public float fFeedback;
        public float fFrequency;
        public float fWetDryMix;
        public int lPhase;
        public int lWaveform;
    }

    public static class BASS_DX8_PARAMEQ {
        public BASS_DX8_PARAMEQ() {}
        public float fBandwidth;
        public float fCenter;
        public float fGain;
    }

    public static class BASS_DX8_REVERB {
        public BASS_DX8_REVERB() {}
        public float fHighFreqRTRatio;
        public float fInGain;
        public float fReverbMix;
        public float fReverbTime;
    }

    public interface BASS_FILEOPENPROCS {
        public java.lang.Object FILEOPENPROC(java.lang.String a0, int a1);
    }

    public interface BASS_FILEPROCS {
        public void FILECLOSEPROC(java.lang.Object a0);
        public long FILELENPROC(java.lang.Object a0);
        public int FILEREADPROC(java.nio.ByteBuffer a0, int a1, java.lang.Object a2);
        public boolean FILESEEKPROC(long a0, java.lang.Object a1);
    }

    public static class BASS_FX_VOLUME_PARAM {
        public BASS_FX_VOLUME_PARAM() {}
        public float fCurrent;
        public float fTarget;
        public float fTime;
        public int lCurve;
    }

    public static class BASS_INFO {
        public BASS_INFO() {}
        public int dsver;
        public int flags;
        public int freq;
        public int initflags;
        public int latency;
        public int minbuf;
        public int speakers;
    }

    public static class BASS_PLUGINFORM {
        public BASS_PLUGINFORM() {}
        public int ctype;
        public java.lang.String exts;
        public java.lang.String name;
    }

    public static class BASS_PLUGININFO {
        public BASS_PLUGININFO() {}
        public int formatc;
        public com.un4seen.bass.BASS.BASS_PLUGINFORM[] formats;
        public int version;
    }

    public static class BASS_RECORDINFO {
        public BASS_RECORDINFO() {}
        public int flags;
        public int formats;
        public int freq;
        public int inputs;
        public boolean singlein;
    }

    public static class BASS_SAMPLE {
        public BASS_SAMPLE() {}
        public int chans;
        public int flags;
        public int freq;
        public int iangle;
        public int length;
        public int max;
        public float maxdist;
        public float mindist;
        public int mingap;
        public int mode3d;
        public int oangle;
        public int origres;
        public float outvol;
        public float pan;
        public float volume;
    }

    public interface DOWNLOADPROC {
        public void DOWNLOADPROC(java.nio.ByteBuffer a0, int a1, java.lang.Object a2);
    }

    public interface DSPPROC {
        public void DSPPROC(int a0, int a1, java.nio.ByteBuffer a2, int a3, java.lang.Object a4);
    }

    public static class FloatValue {
        public FloatValue() {}
        public float value;
    }

    public static class IntValue {
        public IntValue() {}
        public int value;
    }

    public interface RECORDPROC {
        public boolean RECORDPROC(int a0, java.nio.ByteBuffer a1, int a2, java.lang.Object a3);
    }

    public interface STREAMPROC {
        public int STREAMPROC(int a0, java.nio.ByteBuffer a1, int a2, java.lang.Object a3);
    }

    public interface SYNCPROC {
        public void SYNCPROC(int a0, int a1, int a2, java.lang.Object a3);
    }

    public static class TAG_APE_BINARY {
        public TAG_APE_BINARY() {}
        public java.lang.String key;
    }

    public static class TAG_BINARY {
        public TAG_BINARY() {}
        public java.nio.ByteBuffer data;
        public int length;
    }

    public static class TAG_ID3 {
        public TAG_ID3() {}
        public java.lang.String album;
        public java.lang.String artist;
        public java.lang.String comment;
        public byte genre;
        public java.lang.String id;
        public java.lang.String title;
        public byte track;
        public java.lang.String year;
    }

    public static class Utils {
        public Utils() {}
        public static int HIBYTE(int a0) { return 0; }
        public static int HIWORD(int a0) { return 0; }
        public static int LOBYTE(int a0) { return 0; }
        public static int LOWORD(int a0) { return 0; }
        public static int MAKELONG(int a0, int a1) { return 0; }
        public static int MAKEWORD(int a0, int a1) { return 0; }
    }

    public static final int BASSVERSION = 516;
    public static final java.lang.String BASSVERSIONTEXT = "2.4";
    public static final int BASS_3DALG_DEFAULT = 0;
    public static final int BASS_3DALG_OFF = 1;
    public static final int BASS_3DMODE_NORMAL = 0;
    public static final int BASS_3DMODE_OFF = 2;
    public static final int BASS_3DMODE_RELATIVE = 1;
    public static final int BASS_ACTIVE_PAUSED = 3;
    public static final int BASS_ACTIVE_PAUSED_DEVICE = 4;
    public static final int BASS_ACTIVE_PLAYING = 1;
    public static final int BASS_ACTIVE_STALLED = 2;
    public static final int BASS_ACTIVE_STOPPED = 0;
    public static final int BASS_ASYNCFILE = 1073741824;
    public static final int BASS_ATTRIBTYPE_FLOAT = -0x1;
    public static final int BASS_ATTRIBTYPE_INT = -0x2;
    public static final int BASS_ATTRIB_BITRATE = 12;
    public static final int BASS_ATTRIB_BUFFER = 13;
    public static final int BASS_ATTRIB_CPU = 7;
    public static final int BASS_ATTRIB_DOWNLOADPROC = 18;
    public static final int BASS_ATTRIB_DOWNMIX = 21;
    public static final int BASS_ATTRIB_EAXMIX = 4;
    public static final int BASS_ATTRIB_FREQ = 1;
    public static final int BASS_ATTRIB_GRANULE = 14;
    public static final int BASS_ATTRIB_MUSIC_AMPLIFY = 256;
    public static final int BASS_ATTRIB_MUSIC_BPM = 259;
    public static final int BASS_ATTRIB_MUSIC_PANSEP = 257;
    public static final int BASS_ATTRIB_MUSIC_PSCALER = 258;
    public static final int BASS_ATTRIB_MUSIC_SPEED = 260;
    public static final int BASS_ATTRIB_MUSIC_VOL_CHAN = 512;
    public static final int BASS_ATTRIB_MUSIC_VOL_GLOBAL = 261;
    public static final int BASS_ATTRIB_MUSIC_VOL_INST = 768;
    public static final int BASS_ATTRIB_NET_RESUME = 9;
    public static final int BASS_ATTRIB_NOBUFFER = 5;
    public static final int BASS_ATTRIB_NORAMP = 11;
    public static final int BASS_ATTRIB_PAN = 3;
    public static final int BASS_ATTRIB_PUSH_LIMIT = 17;
    public static final int BASS_ATTRIB_SCANINFO = 10;
    public static final int BASS_ATTRIB_SRC = 8;
    public static final int BASS_ATTRIB_TAIL = 16;
    public static final int BASS_ATTRIB_USER = 15;
    public static final int BASS_ATTRIB_VBR = 6;
    public static final int BASS_ATTRIB_VOL = 2;
    public static final int BASS_ATTRIB_VOLDSP = 19;
    public static final int BASS_ATTRIB_VOLDSP_PRIORITY = 20;
    public static final int BASS_CONFIG_3DALGORITHM = 10;
    public static final int BASS_CONFIG_AM_DISABLE = 58;
    public static final int BASS_CONFIG_ANDROID_AAUDIO = 67;
    public static final int BASS_CONFIG_ANDROID_SESSIONID = 62;
    public static final int BASS_CONFIG_ASYNCFILE_BUFFER = 45;
    public static final int BASS_CONFIG_BUFFER = 0;
    public static final int BASS_CONFIG_CURVE_PAN = 8;
    public static final int BASS_CONFIG_CURVE_VOL = 7;
    public static final int BASS_CONFIG_DEV_BUFFER = 27;
    public static final int BASS_CONFIG_DEV_DEFAULT = 36;
    public static final int BASS_CONFIG_DEV_NONSTOP = 50;
    public static final int BASS_CONFIG_DEV_PERIOD = 53;
    public static final int BASS_CONFIG_DEV_TIMEOUT = 70;
    public static final int BASS_CONFIG_DOWNMIX = 80;
    public static final int BASS_CONFIG_FILENAME = 75;
    public static final int BASS_CONFIG_FILEOPENPROCS = 77;
    public static final int BASS_CONFIG_FLOAT = 54;
    public static final int BASS_CONFIG_FLOATDSP = 9;
    public static final int BASS_CONFIG_GVOL_MUSIC = 6;
    public static final int BASS_CONFIG_GVOL_SAMPLE = 4;
    public static final int BASS_CONFIG_GVOL_STREAM = 5;
    public static final int BASS_CONFIG_HANDLES = 41;
    public static final int BASS_CONFIG_LIBSSL = 64;
    public static final int BASS_CONFIG_MUSIC_VIRTUAL = 22;
    public static final int BASS_CONFIG_NET_AGENT = 16;
    public static final int BASS_CONFIG_NET_BUFFER = 12;
    public static final int BASS_CONFIG_NET_META = 71;
    public static final int BASS_CONFIG_NET_PASSIVE = 18;
    public static final int BASS_CONFIG_NET_PLAYLIST = 21;
    public static final int BASS_CONFIG_NET_PLAYLIST_DEPTH = 59;
    public static final int BASS_CONFIG_NET_PREBUF = 15;
    public static final int BASS_CONFIG_NET_PREBUF_WAIT = 60;
    public static final int BASS_CONFIG_NET_PROXY = 17;
    public static final int BASS_CONFIG_NET_READTIMEOUT = 37;
    public static final int BASS_CONFIG_NET_RESTRATE = 72;
    public static final int BASS_CONFIG_NET_SEEK = 56;
    public static final int BASS_CONFIG_NET_TIMEOUT = 11;
    public static final int BASS_CONFIG_NORAMP = 74;
    public static final int BASS_CONFIG_NOSOUND_MAXDELAY = 76;
    public static final int BASS_CONFIG_OGG_PRESCAN = 47;
    public static final int BASS_CONFIG_PAUSE_NOPLAY = 13;
    public static final int BASS_CONFIG_REC_BUFFER = 19;
    public static final int BASS_CONFIG_REC_DEFAULT = 73;
    public static final int BASS_CONFIG_SAMPLE_ONEHANDLE = 69;
    public static final int BASS_CONFIG_SRC = 43;
    public static final int BASS_CONFIG_SRC_SAMPLE = 44;
    public static final int BASS_CONFIG_STACKALLOC = 79;
    public static final int BASS_CONFIG_THREAD = 1073741824;
    public static final int BASS_CONFIG_UPDATEPERIOD = 1;
    public static final int BASS_CONFIG_UPDATETHREADS = 24;
    public static final int BASS_CONFIG_VERIFY = 23;
    public static final int BASS_CONFIG_VERIFY_NET = 52;
    public static final int BASS_CONFIG_VIDEO = 48;
    public static final int BASS_CTYPE_MUSIC_IT = 131076;
    public static final int BASS_CTYPE_MUSIC_MO3 = 256;
    public static final int BASS_CTYPE_MUSIC_MOD = 131072;
    public static final int BASS_CTYPE_MUSIC_MTM = 131073;
    public static final int BASS_CTYPE_MUSIC_S3M = 131074;
    public static final int BASS_CTYPE_MUSIC_XM = 131075;
    public static final int BASS_CTYPE_RECORD = 2;
    public static final int BASS_CTYPE_SAMPLE = 1;
    public static final int BASS_CTYPE_STREAM = 65536;
    public static final int BASS_CTYPE_STREAM_AIFF = 65542;
    public static final int BASS_CTYPE_STREAM_AM = 65545;
    public static final int BASS_CTYPE_STREAM_CA = 65543;
    public static final int BASS_CTYPE_STREAM_DEVICE = 98305;
    public static final int BASS_CTYPE_STREAM_DUMMY = 98304;
    public static final int BASS_CTYPE_STREAM_MF = 65544;
    public static final int BASS_CTYPE_STREAM_MP1 = 65539;
    public static final int BASS_CTYPE_STREAM_MP2 = 65540;
    public static final int BASS_CTYPE_STREAM_MP3 = 65541;
    public static final int BASS_CTYPE_STREAM_OGG = 65538;
    public static final int BASS_CTYPE_STREAM_SAMPLE = 65546;
    public static final int BASS_CTYPE_STREAM_VORBIS = 65538;
    public static final int BASS_CTYPE_STREAM_WAV = 262144;
    public static final int BASS_CTYPE_STREAM_WAV_FLOAT = 327683;
    public static final int BASS_CTYPE_STREAM_WAV_PCM = 327681;
    public static final int BASS_DATA_AVAILABLE = 0;
    public static final int BASS_DATA_FFT1024 = -0x7ffffffe;
    public static final int BASS_DATA_FFT16384 = -0x7ffffffa;
    public static final int BASS_DATA_FFT2048 = -0x7ffffffd;
    public static final int BASS_DATA_FFT256 = -0x80000000;
    public static final int BASS_DATA_FFT32768 = -0x7ffffff9;
    public static final int BASS_DATA_FFT4096 = -0x7ffffffc;
    public static final int BASS_DATA_FFT512 = -0x7fffffff;
    public static final int BASS_DATA_FFT8192 = -0x7ffffffb;
    public static final int BASS_DATA_FFT_COMPLEX = 128;
    public static final int BASS_DATA_FFT_INDIVIDUAL = 16;
    public static final int BASS_DATA_FFT_NOWINDOW = 32;
    public static final int BASS_DATA_FFT_NYQUIST = 256;
    public static final int BASS_DATA_FFT_REMOVEDC = 64;
    public static final int BASS_DATA_FIXED = 536870912;
    public static final int BASS_DATA_FLOAT = 1073741824;
    public static final int BASS_DATA_NOREMOVE = 268435456;
    public static final int BASS_DEVICE_16BITS = 8;
    public static final int BASS_DEVICE_3D = 4;
    public static final int BASS_DEVICE_8BITS = 1;
    public static final int BASS_DEVICE_AUDIOTRACK = 131072;
    public static final int BASS_DEVICE_DEFAULT = 2;
    public static final int BASS_DEVICE_ENABLED = 1;
    public static final int BASS_DEVICE_FREQ = 16384;
    public static final int BASS_DEVICE_INIT = 4;
    public static final int BASS_DEVICE_LATENCY = 256;
    public static final int BASS_DEVICE_MONO = 2;
    public static final int BASS_DEVICE_NOSPEAKER = 4096;
    public static final int BASS_DEVICE_OPENSLES = 1048576;
    public static final int BASS_DEVICE_REINIT = 128;
    public static final int BASS_DEVICE_SOFTWARE = 524288;
    public static final int BASS_DEVICE_SPEAKERS = 2048;
    public static final int BASS_DSP_BYPASS = 4194304;
    public static final int BASS_DSP_FLOAT = 2;
    public static final int BASS_DSP_FREECALL = 4;
    public static final int BASS_DSP_READONLY = 1;
    public static final int BASS_DX8_PHASE_180 = 4;
    public static final int BASS_DX8_PHASE_90 = 3;
    public static final int BASS_DX8_PHASE_NEG_180 = 0;
    public static final int BASS_DX8_PHASE_NEG_90 = 1;
    public static final int BASS_DX8_PHASE_ZERO = 2;
    public static final int BASS_ERROR_ALREADY = 14;
    public static final int BASS_ERROR_BUFLOST = 4;
    public static final int BASS_ERROR_BUSY = 46;
    public static final int BASS_ERROR_CANCEL = 51;
    public static final int BASS_ERROR_CODEC = 44;
    public static final int BASS_ERROR_CREATE = 33;
    public static final int BASS_ERROR_DECODE = 38;
    public static final int BASS_ERROR_DENIED = 49;
    public static final int BASS_ERROR_DEVICE = 23;
    public static final int BASS_ERROR_DRIVER = 3;
    public static final int BASS_ERROR_DX = 39;
    public static final int BASS_ERROR_EMPTY = 31;
    public static final int BASS_ERROR_ENDED = 45;
    public static final int BASS_ERROR_FILEFORM = 41;
    public static final int BASS_ERROR_FILEOPEN = 2;
    public static final int BASS_ERROR_FORMAT = 6;
    public static final int BASS_ERROR_FREEING = 50;
    public static final int BASS_ERROR_FREQ = 25;
    public static final int BASS_ERROR_HANDLE = 5;
    public static final int BASS_ERROR_ILLPARAM = 20;
    public static final int BASS_ERROR_ILLTYPE = 19;
    public static final int BASS_ERROR_INIT = 8;
    public static final int BASS_ERROR_JAVA_CLASS = 500;
    public static final int BASS_ERROR_MEM = 1;
    public static final int BASS_ERROR_NO3D = 21;
    public static final int BASS_ERROR_NOCHAN = 18;
    public static final int BASS_ERROR_NOEAX = 22;
    public static final int BASS_ERROR_NOFX = 34;
    public static final int BASS_ERROR_NOHW = 29;
    public static final int BASS_ERROR_NONET = 32;
    public static final int BASS_ERROR_NOPLAY = 24;
    public static final int BASS_ERROR_NOTAUDIO = 17;
    public static final int BASS_ERROR_NOTAVAIL = 37;
    public static final int BASS_ERROR_NOTFILE = 27;
    public static final int BASS_ERROR_POSITION = 7;
    public static final int BASS_ERROR_PROTOCOL = 48;
    public static final int BASS_ERROR_REINIT = 11;
    public static final int BASS_ERROR_SPEAKER = 42;
    public static final int BASS_ERROR_SSL = 10;
    public static final int BASS_ERROR_START = 9;
    public static final int BASS_ERROR_TIMEOUT = 40;
    public static final int BASS_ERROR_TRACK = 13;
    public static final int BASS_ERROR_UNKNOWN = -0x1;
    public static final int BASS_ERROR_UNSTREAMABLE = 47;
    public static final int BASS_ERROR_VERSION = 43;
    public static final int BASS_FILEDATA_END = 0;
    public static final int BASS_FILEPOS_ASYNCBUF = 7;
    public static final int BASS_FILEPOS_ASYNCSIZE = 12;
    public static final int BASS_FILEPOS_AVAILABLE = 10;
    public static final int BASS_FILEPOS_BUFFER = 5;
    public static final int BASS_FILEPOS_BUFFERING = 9;
    public static final int BASS_FILEPOS_CONNECTED = 4;
    public static final int BASS_FILEPOS_CURRENT = 0;
    public static final int BASS_FILEPOS_DECODE = 0;
    public static final int BASS_FILEPOS_DOWNLOAD = 1;
    public static final int BASS_FILEPOS_END = 2;
    public static final int BASS_FILEPOS_SIZE = 8;
    public static final int BASS_FILEPOS_SOCKET = 6;
    public static final int BASS_FILEPOS_START = 3;
    public static final int BASS_FX_DX8_CHORUS = 0;
    public static final int BASS_FX_DX8_COMPRESSOR = 1;
    public static final int BASS_FX_DX8_DISTORTION = 2;
    public static final int BASS_FX_DX8_ECHO = 3;
    public static final int BASS_FX_DX8_FLANGER = 4;
    public static final int BASS_FX_DX8_GARGLE = 5;
    public static final int BASS_FX_DX8_I3DL2REVERB = 6;
    public static final int BASS_FX_DX8_PARAMEQ = 7;
    public static final int BASS_FX_DX8_REVERB = 8;
    public static final int BASS_FX_VOLUME = 9;
    public static final int BASS_LEVEL_MONO = 1;
    public static final int BASS_LEVEL_NOREMOVE = 16;
    public static final int BASS_LEVEL_RMS = 4;
    public static final int BASS_LEVEL_STEREO = 2;
    public static final int BASS_LEVEL_VOLPAN = 8;
    public static final int BASS_MP3_IGNOREDELAY = 512;
    public static final int BASS_MP3_SETPOS = 131072;
    public static final int BASS_MUSIC_3D = 8;
    public static final int BASS_MUSIC_AUTOFREE = 262144;
    public static final int BASS_MUSIC_CALCLEN = 131072;
    public static final int BASS_MUSIC_DECODE = 2097152;
    public static final int BASS_MUSIC_FLOAT = 256;
    public static final int BASS_MUSIC_FT2MOD = 8192;
    public static final int BASS_MUSIC_FT2PAN = 8192;
    public static final int BASS_MUSIC_FX = 128;
    public static final int BASS_MUSIC_LOOP = 4;
    public static final int BASS_MUSIC_MONO = 2;
    public static final int BASS_MUSIC_NONINTER = 65536;
    public static final int BASS_MUSIC_NOSAMPLE = 1048576;
    public static final int BASS_MUSIC_POSRESET = 32768;
    public static final int BASS_MUSIC_POSRESETEX = 4194304;
    public static final int BASS_MUSIC_PRESCAN = 131072;
    public static final int BASS_MUSIC_PT1MOD = 16384;
    public static final int BASS_MUSIC_RAMP = 512;
    public static final int BASS_MUSIC_RAMPS = 1024;
    public static final int BASS_MUSIC_SINCINTER = 8388608;
    public static final int BASS_MUSIC_STOPBACK = 524288;
    public static final int BASS_MUSIC_SURROUND = 2048;
    public static final int BASS_MUSIC_SURROUND2 = 4096;
    public static final int BASS_NODEVICE = 131072;
    public static final int BASS_OK = 0;
    public static final int BASS_ORIGRES_FLOAT = 65536;
    public static final int BASS_POS_BYTE = 0;
    public static final int BASS_POS_DECODE = 268435456;
    public static final int BASS_POS_DECODETO = 536870912;
    public static final int BASS_POS_END = 16;
    public static final int BASS_POS_FLUSH = 16777216;
    public static final int BASS_POS_INEXACT = 134217728;
    public static final int BASS_POS_LOOP = 17;
    public static final int BASS_POS_MUSIC_ORDER = 1;
    public static final int BASS_POS_OGG = 3;
    public static final int BASS_POS_RAW = 6;
    public static final int BASS_POS_RELATIVE = 67108864;
    public static final int BASS_POS_RESET = 33554432;
    public static final int BASS_POS_SCAN = 1073741824;
    public static final int BASS_POS_TRACK = 4;
    public static final int BASS_RECORD_OPENSLES = 4096;
    public static final int BASS_RECORD_PAUSE = 32768;
    public static final int BASS_SAMCHAN_NEW = 1;
    public static final int BASS_SAMCHAN_STREAM = 2;
    public static final int BASS_SAMPLE_3D = 8;
    public static final int BASS_SAMPLE_8BITS = 1;
    public static final int BASS_SAMPLE_FLOAT = 256;
    public static final int BASS_SAMPLE_FX = 128;
    public static final int BASS_SAMPLE_LOOP = 4;
    public static final int BASS_SAMPLE_MONO = 2;
    public static final int BASS_SAMPLE_MUTEMAX = 32;
    public static final int BASS_SAMPLE_NOREORDER = 64;
    public static final int BASS_SAMPLE_OVER_DIST = 196608;
    public static final int BASS_SAMPLE_OVER_POS = 131072;
    public static final int BASS_SAMPLE_OVER_VOL = 65536;
    public static final int BASS_SAMPLE_SOFTWARE = 16;
    public static final int BASS_SLIDE_LOG = 16777216;
    public static final int BASS_SPEAKER_CENLFE = 50331648;
    public static final int BASS_SPEAKER_CENTER = 318767104;
    public static final int BASS_SPEAKER_FRONT = 16777216;
    public static final int BASS_SPEAKER_FRONTLEFT = 285212672;
    public static final int BASS_SPEAKER_FRONTRIGHT = 553648128;
    public static final int BASS_SPEAKER_LEFT = 268435456;
    public static final int BASS_SPEAKER_LFE = 587202560;
    public static final int BASS_SPEAKER_REAR = 33554432;
    public static final int BASS_SPEAKER_REAR2 = 67108864;
    public static final int BASS_SPEAKER_REAR2LEFT = 335544320;
    public static final int BASS_SPEAKER_REAR2RIGHT = 603979776;
    public static final int BASS_SPEAKER_REARLEFT = 301989888;
    public static final int BASS_SPEAKER_REARRIGHT = 570425344;
    public static final int BASS_SPEAKER_RIGHT = 536870912;
    public static final int BASS_SPEAKER_SIDE = 67108864;
    public static final int BASS_SPEAKER_SIDELEFT = 335544320;
    public static final int BASS_SPEAKER_SIDERIGHT = 603979776;
    public static final int BASS_STREAMPROC_AGAIN = 1073741824;
    public static final int BASS_STREAMPROC_END = -0x80000000;
    public static final int BASS_STREAM_AUTOFREE = 262144;
    public static final int BASS_STREAM_BLOCK = 1048576;
    public static final int BASS_STREAM_DECODE = 2097152;
    public static final int BASS_STREAM_PRESCAN = 131072;
    public static final int BASS_STREAM_RESTRATE = 524288;
    public static final int BASS_STREAM_STATUS = 8388608;
    public static final int BASS_SYNC_ATTRIB = 13;
    public static final int BASS_SYNC_DEV_FAIL = 14;
    public static final int BASS_SYNC_DEV_FORMAT = 15;
    public static final int BASS_SYNC_DOWNLOAD = 7;
    public static final int BASS_SYNC_END = 2;
    public static final int BASS_SYNC_FREE = 8;
    public static final int BASS_SYNC_META = 4;
    public static final int BASS_SYNC_MIXTIME = 1073741824;
    public static final int BASS_SYNC_MUSICFX = 3;
    public static final int BASS_SYNC_MUSICINST = 1;
    public static final int BASS_SYNC_MUSICPOS = 10;
    public static final int BASS_SYNC_OGG_CHANGE = 12;
    public static final int BASS_SYNC_ONETIME = -0x80000000;
    public static final int BASS_SYNC_POS = 0;
    public static final int BASS_SYNC_POS_RAW = 16;
    public static final int BASS_SYNC_SETPOS = 11;
    public static final int BASS_SYNC_SLIDE = 5;
    public static final int BASS_SYNC_STALL = 6;
    public static final int BASS_SYNC_THREAD = 536870912;
    public static final int BASS_TAG_AM_MIME = 18;
    public static final int BASS_TAG_AM_NAME = 16;
    public static final int BASS_TAG_APE = 6;
    public static final int BASS_TAG_APE_BINARY = 4096;
    public static final int BASS_TAG_BYTEBUFFER = 268435456;
    public static final int BASS_TAG_HTTP = 3;
    public static final int BASS_TAG_ICY = 4;
    public static final int BASS_TAG_ID3 = 0;
    public static final int BASS_TAG_ID3V2 = 1;
    public static final int BASS_TAG_ID3V2_2 = 17;
    public static final int BASS_TAG_ID3V2_2_BINARY = 21;
    public static final int BASS_TAG_ID3V2_BINARY = 20;
    public static final int BASS_TAG_INCREF = 536870912;
    public static final int BASS_TAG_LOCATION = 19;
    public static final int BASS_TAG_LYRICS3 = 10;
    public static final int BASS_TAG_META = 5;
    public static final int BASS_TAG_MP4 = 7;
    public static final int BASS_TAG_MP4_COVERART = 5120;
    public static final int BASS_TAG_MUSIC_AUTH = 65539;
    public static final int BASS_TAG_MUSIC_CHAN = 66048;
    public static final int BASS_TAG_MUSIC_INST = 65792;
    public static final int BASS_TAG_MUSIC_MESSAGE = 65537;
    public static final int BASS_TAG_MUSIC_NAME = 65536;
    public static final int BASS_TAG_MUSIC_ORDERS = 65538;
    public static final int BASS_TAG_MUSIC_SAMPLE = 66304;
    public static final int BASS_TAG_OGG = 2;
    public static final int BASS_TAG_RIFF_BEXT = 257;
    public static final int BASS_TAG_RIFF_CART = 258;
    public static final int BASS_TAG_RIFF_CUE = 260;
    public static final int BASS_TAG_RIFF_DISP = 259;
    public static final int BASS_TAG_RIFF_INFO = 256;
    public static final int BASS_TAG_RIFF_SMPL = 261;
    public static final int BASS_TAG_VENDOR = 9;
    public static final int BASS_TAG_WAVEFORMAT = 14;
    public static final int RECORDPROC_NONE = 0;
    public static final int RECORDPROC_TRUE = -0x1;
    public static final int STREAMFILE_BUFFER = 1;
    public static final int STREAMFILE_BUFFERPUSH = 2;
    public static final int STREAMFILE_NOBUFFER = 0;
    public static final int STREAMPROC_DEVICE = -0x2;
    public static final int STREAMPROC_DEVICE_3D = -0x3;
    public static final int STREAMPROC_DUMMY = 0;
    public static final int STREAMPROC_PUSH = -0x1;
    public static native void BASS_Apply3D();
    public static native double BASS_ChannelBytes2Seconds(int a0, long a1);
    public static native long BASS_ChannelFlags(int a0, int a1, int a2);
    public static native boolean BASS_ChannelFree(int a0);
    public static native boolean BASS_ChannelGet3DAttributes(int a0, com.un4seen.bass.BASS.IntValue a1, com.un4seen.bass.BASS.FloatValue a2, com.un4seen.bass.BASS.FloatValue a3, com.un4seen.bass.BASS.IntValue a4, com.un4seen.bass.BASS.IntValue a5, com.un4seen.bass.BASS.FloatValue a6);
    public static native boolean BASS_ChannelGet3DPosition(int a0, com.un4seen.bass.BASS.BASS_3DVECTOR a1, com.un4seen.bass.BASS.BASS_3DVECTOR a2, com.un4seen.bass.BASS.BASS_3DVECTOR a3);
    public static native boolean BASS_ChannelGetAttribute(int a0, int a1, com.un4seen.bass.BASS.FloatValue a2);
    public static native int BASS_ChannelGetAttributeEx(int a0, int a1, com.un4seen.bass.BASS.FloatValue a2, int a3);
    public static native int BASS_ChannelGetAttributeEx(int a0, int a1, com.un4seen.bass.BASS.IntValue a2, int a3);
    public static native int BASS_ChannelGetAttributeEx(int a0, int a1, java.nio.ByteBuffer a2, int a3);
    public static native int BASS_ChannelGetData(int a0, java.nio.ByteBuffer a1, int a2);
    public static native int BASS_ChannelGetDevice(int a0);
    public static native boolean BASS_ChannelGetInfo(int a0, com.un4seen.bass.BASS.BASS_CHANNELINFO a1);
    public static native long BASS_ChannelGetLength(int a0, int a1);
    public static native int BASS_ChannelGetLevel(int a0);
    public static native boolean BASS_ChannelGetLevelEx(int a0, float[] a1, float a2, int a3);
    public static native long BASS_ChannelGetPosition(int a0, int a1);
    public static native java.lang.Object BASS_ChannelGetTags(int a0, int a1);
    public static native int BASS_ChannelIsActive(int a0);
    public static native boolean BASS_ChannelIsSliding(int a0, int a1);
    public static native boolean BASS_ChannelLock(int a0, boolean a1);
    public static native boolean BASS_ChannelPause(int a0);
    public static native boolean BASS_ChannelPlay(int a0, boolean a1);
    public static native boolean BASS_ChannelRef(int a0, boolean a1);
    public static native boolean BASS_ChannelRemoveDSP(int a0, int a1);
    public static native boolean BASS_ChannelRemoveFX(int a0, int a1);
    public static native boolean BASS_ChannelRemoveLink(int a0, int a1);
    public static native boolean BASS_ChannelRemoveSync(int a0, int a1);
    public static native long BASS_ChannelSeconds2Bytes(int a0, double a1);
    public static native boolean BASS_ChannelSet3DAttributes(int a0, int a1, float a2, float a3, int a4, int a5, float a6);
    public static native boolean BASS_ChannelSet3DPosition(int a0, com.un4seen.bass.BASS.BASS_3DVECTOR a1, com.un4seen.bass.BASS.BASS_3DVECTOR a2, com.un4seen.bass.BASS.BASS_3DVECTOR a3);
    public static native boolean BASS_ChannelSetAttribute(int a0, int a1, float a2);
    public static native boolean BASS_ChannelSetAttributeDOWNLOADPROC(int a0, com.un4seen.bass.BASS.DOWNLOADPROC a1, java.lang.Object a2);
    public static native boolean BASS_ChannelSetAttributeEx(int a0, int a1, com.un4seen.bass.BASS.FloatValue a2, int a3);
    public static native boolean BASS_ChannelSetAttributeEx(int a0, int a1, com.un4seen.bass.BASS.IntValue a2, int a3);
    public static native boolean BASS_ChannelSetAttributeEx(int a0, int a1, java.nio.ByteBuffer a2, int a3);
    public static native int BASS_ChannelSetDSP(int a0, com.un4seen.bass.BASS.DSPPROC a1, java.lang.Object a2, int a3);
    public static native int BASS_ChannelSetDSPEx(int a0, com.un4seen.bass.BASS.DSPPROC a1, java.lang.Object a2, int a3, int a4);
    public static native boolean BASS_ChannelSetDevice(int a0, int a1);
    public static native int BASS_ChannelSetFX(int a0, int a1, int a2);
    public static native boolean BASS_ChannelSetLink(int a0, int a1);
    public static native boolean BASS_ChannelSetPosition(int a0, long a1, int a2);
    public static native int BASS_ChannelSetSync(int a0, int a1, long a2, com.un4seen.bass.BASS.SYNCPROC a3, java.lang.Object a4);
    public static native boolean BASS_ChannelSlideAttribute(int a0, int a1, float a2, int a3);
    public static native boolean BASS_ChannelStart(int a0);
    public static native boolean BASS_ChannelStop(int a0);
    public static native boolean BASS_ChannelUpdate(int a0, int a1);
    public static int BASS_DSP_MONO_N(int a0) { return 0; }
    public static int BASS_DSP_STEREO_N(int a0) { return 0; }
    public static native int BASS_ErrorGetCode();
    public static native boolean BASS_FXFree(int a0);
    public static native boolean BASS_FXGetParameters(int a0, java.lang.Object a1);
    public static native boolean BASS_FXReset(int a0);
    public static native boolean BASS_FXSetBypass(int a0, boolean a1);
    public static native boolean BASS_FXSetParameters(int a0, java.lang.Object a1);
    public static native boolean BASS_FXSetPriority(int a0, int a1);
    public static native boolean BASS_Free();
    public static native boolean BASS_Get3DFactors(com.un4seen.bass.BASS.FloatValue a0, com.un4seen.bass.BASS.FloatValue a1, com.un4seen.bass.BASS.FloatValue a2);
    public static native boolean BASS_Get3DPosition(com.un4seen.bass.BASS.BASS_3DVECTOR a0, com.un4seen.bass.BASS.BASS_3DVECTOR a1, com.un4seen.bass.BASS.BASS_3DVECTOR a2, com.un4seen.bass.BASS.BASS_3DVECTOR a3);
    public static native float BASS_GetCPU();
    public static native int BASS_GetConfig(int a0);
    public static native java.lang.Object BASS_GetConfigPtr(int a0);
    public static native int BASS_GetDevice();
    public static native boolean BASS_GetDeviceInfo(int a0, com.un4seen.bass.BASS.BASS_DEVICEINFO a1);
    public static native boolean BASS_GetInfo(com.un4seen.bass.BASS.BASS_INFO a0);
    public static native int BASS_GetVersion();
    public static native float BASS_GetVolume();
    public static native boolean BASS_Init(int a0, int a1, int a2);
    public static native int BASS_IsStarted();
    public static native boolean BASS_MusicFree(int a0);
    public static native int BASS_MusicLoad(android.os.ParcelFileDescriptor a0, long a1, int a2, int a3, int a4);
    public static native int BASS_MusicLoad(com.un4seen.bass.BASS.Asset a0, long a1, int a2, int a3, int a4);
    public static native int BASS_MusicLoad(java.lang.String a0, long a1, int a2, int a3, int a4);
    public static native int BASS_MusicLoad(java.nio.ByteBuffer a0, long a1, int a2, int a3, int a4);
    public static native boolean BASS_Pause();
    public static native boolean BASS_PluginEnable(int a0, boolean a1);
    public static native boolean BASS_PluginFree(int a0);
    public static native com.un4seen.bass.BASS.BASS_PLUGININFO BASS_PluginGetInfo(int a0);
    public static native int BASS_PluginLoad(java.lang.String a0, int a1);
    public static native boolean BASS_RecordFree();
    public static native int BASS_RecordGetDevice();
    public static native boolean BASS_RecordGetDeviceInfo(int a0, com.un4seen.bass.BASS.BASS_DEVICEINFO a1);
    public static native boolean BASS_RecordGetInfo(com.un4seen.bass.BASS.BASS_RECORDINFO a0);
    public static native int BASS_RecordGetInput(int a0, com.un4seen.bass.BASS.FloatValue a1);
    public static native java.lang.String BASS_RecordGetInputName(int a0);
    public static native boolean BASS_RecordInit(int a0);
    public static native boolean BASS_RecordSetDevice(int a0);
    public static native boolean BASS_RecordSetInput(int a0, int a1, float a2);
    public static native int BASS_RecordStart(int a0, int a1, int a2, int a3, java.lang.Object a4);
    public static native int BASS_RecordStart(int a0, int a1, int a2, com.un4seen.bass.BASS.RECORDPROC a3, java.lang.Object a4);
    public static int BASS_SPEAKER_N(int a0) { return 0; }
    public static native int BASS_SampleCreate(int a0, int a1, int a2, int a3, int a4);
    public static native boolean BASS_SampleFree(int a0);
    public static native int BASS_SampleGetChannel(int a0, int a1);
    public static native int BASS_SampleGetChannels(int a0, int[] a1);
    public static native boolean BASS_SampleGetData(int a0, java.nio.ByteBuffer a1);
    public static native boolean BASS_SampleGetInfo(int a0, com.un4seen.bass.BASS.BASS_SAMPLE a1);
    public static native int BASS_SampleLoad(android.os.ParcelFileDescriptor a0, long a1, int a2, int a3, int a4);
    public static native int BASS_SampleLoad(com.un4seen.bass.BASS.Asset a0, long a1, int a2, int a3, int a4);
    public static native int BASS_SampleLoad(java.lang.String a0, long a1, int a2, int a3, int a4);
    public static native int BASS_SampleLoad(java.nio.ByteBuffer a0, long a1, int a2, int a3, int a4);
    public static native boolean BASS_SampleSetData(int a0, java.nio.ByteBuffer a1);
    public static native boolean BASS_SampleSetInfo(int a0, com.un4seen.bass.BASS.BASS_SAMPLE a1);
    public static native boolean BASS_SampleStop(int a0);
    public static native boolean BASS_Set3DFactors(float a0, float a1, float a2);
    public static native boolean BASS_Set3DPosition(com.un4seen.bass.BASS.BASS_3DVECTOR a0, com.un4seen.bass.BASS.BASS_3DVECTOR a1, com.un4seen.bass.BASS.BASS_3DVECTOR a2, com.un4seen.bass.BASS.BASS_3DVECTOR a3);
    public static native boolean BASS_SetConfig(int a0, int a1);
    public static native boolean BASS_SetConfigPtr(int a0, java.lang.Object a1);
    public static native boolean BASS_SetDevice(int a0);
    public static native boolean BASS_SetVolume(float a0);
    public static native boolean BASS_Start();
    public static native boolean BASS_Stop();
    public static native boolean BASS_StreamCancel(java.lang.Object a0);
    public static native int BASS_StreamCreate(int a0, int a1, int a2, int a3, java.lang.Object a4);
    public static native int BASS_StreamCreate(int a0, int a1, int a2, com.un4seen.bass.BASS.STREAMPROC a3, java.lang.Object a4);
    public static native int BASS_StreamCreateFile(android.os.ParcelFileDescriptor a0, long a1, long a2, int a3);
    public static native int BASS_StreamCreateFile(com.un4seen.bass.BASS.Asset a0, long a1, long a2, int a3);
    public static native int BASS_StreamCreateFile(java.lang.String a0, long a1, long a2, int a3);
    public static native int BASS_StreamCreateFile(java.nio.ByteBuffer a0, long a1, long a2, int a3);
    public static native int BASS_StreamCreateFileUser(int a0, int a1, com.un4seen.bass.BASS.BASS_FILEPROCS a2, java.lang.Object a3);
    public static native int BASS_StreamCreateURL(java.lang.String a0, int a1, int a2, com.un4seen.bass.BASS.DOWNLOADPROC a3, java.lang.Object a4);
    public static native boolean BASS_StreamFree(int a0);
    public static native long BASS_StreamGetFilePosition(int a0, int a1);
    public static native int BASS_StreamPutData(int a0, java.nio.ByteBuffer a1, int a2);
    public static native int BASS_StreamPutFileData(int a0, java.nio.ByteBuffer a1, int a2);
    public static native boolean BASS_Update(int a0);
}