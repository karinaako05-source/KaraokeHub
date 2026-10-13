package com.songhub.android.database

object NativeLib {
    init {
        try {
            System.loadLibrary("c++_shared")
            System.loadLibrary("Mewtwo")
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    @JvmStatic external fun getDeviceIdHash(id: String): String
    @JvmStatic external fun isActivated(): Boolean
    @JvmStatic external fun processMidiData(data: ByteArray, flag: Boolean): ByteArray?
    @JvmStatic external fun verifyDiagnosticPassword(password: String): Boolean
    @JvmStatic external fun verifyLicenseKey(key: String, secret: String): Boolean
}
