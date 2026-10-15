package com.echovault.android.security

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** AES-256-GCM. A fresh random IV is stored as the first 12 bytes of each file. */
class AudioCrypto(private val keyAlias: String = "echovault.audio.v1") {
    private val transformation = "AES/GCM/NoPadding"
    private val ivSize = 12
    private val tagBits = 128

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(keyAlias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setRandomizedEncryptionRequired(true)
            .build())
        return generator.generateKey()
    }

    fun encrypt(plain: ByteArray, destination: File) {
        val cipher = Cipher.getInstance(transformation).apply { init(Cipher.ENCRYPT_MODE, key()) }
        val encrypted = cipher.doFinal(plain)
        destination.outputStream().buffered().use { out -> out.write(cipher.iv); out.write(encrypted) }
    }

    fun decrypt(source: File): ByteArray {
        val all = source.inputStream().buffered().use { it.readBytes() }
        require(all.size > ivSize + 16) { "Encrypted audio file is truncated" }
        val iv = all.copyOfRange(0, ivSize)
        val ciphertext = all.copyOfRange(ivSize, all.size)
        val cipher = Cipher.getInstance(transformation).apply { init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(tagBits, iv)) }
        return cipher.doFinal(ciphertext)
    }
}
