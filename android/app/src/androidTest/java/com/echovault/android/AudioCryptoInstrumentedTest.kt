package com.echovault.android

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.echovault.android.security.AudioCrypto
import java.io.File
import org.junit.Assert.assertArrayEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AudioCryptoInstrumentedTest {
    @Test fun encryptsAndDecryptsBytes() {
        val context = androidx.test.platform.app.InstrumentationRegistry.getInstrumentation().targetContext
        val crypto = AudioCrypto("test.echovault.${System.currentTimeMillis()}")
        val plain = byteArrayOf(1, 2, 3, 4, 5)
        val file = File.createTempFile("crypto-test", ".bin", context.cacheDir)
        try { crypto.encrypt(plain, file); assertArrayEquals(plain, crypto.decrypt(file)) } finally { file.delete() }
    }
}
