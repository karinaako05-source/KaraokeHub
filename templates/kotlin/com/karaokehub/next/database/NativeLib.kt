package com.karaokehub.next.database

import androidx.annotation.Keep

@Keep
object NativeLib {
    init {
        try {
            System.loadLibrary("c++_shared")
            System.loadLibrary("KhNext")
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    @Keep @JvmStatic external fun getDeviceIdHash(id: String): String
    @Keep @JvmStatic external fun isActivated(): Boolean
    @Keep @JvmStatic external fun processMidiData(data: ByteArray, flag: Boolean): ByteArray?
    @Keep @JvmStatic external fun verifyDiagnosticPassword(password: String): Boolean
    @Keep @JvmStatic external fun verifyLicenseKey(key: String, secret: String): Boolean
}
