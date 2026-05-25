package com.apoorvdarshan.delts

import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

private const val ANDROID_KEYSTORE = "AndroidKeyStore"
private const val GEMINI_KEY_ALIAS = "delts_gemini_api_key"
private const val GEMINI_API_KEY_LEGACY = "gemini_api_key"
private const val GEMINI_API_KEY_CIPHER = "gemini_api_key_cipher"
private const val GEMINI_API_KEY_IV = "gemini_api_key_iv"

class GeminiKeyStore(private val settings: SharedPreferences) {
    fun load(): String {
        val encryptedKey = settings.getString(GEMINI_API_KEY_CIPHER, null)
        val iv = settings.getString(GEMINI_API_KEY_IV, null)

        if (!encryptedKey.isNullOrBlank() && !iv.isNullOrBlank()) {
            return decrypt(encryptedKey, iv).orEmpty()
        }

        val legacyKey = settings.getString(GEMINI_API_KEY_LEGACY, null)?.trim().orEmpty()
        if (legacyKey.isNotEmpty()) {
            save(legacyKey)
        }
        return legacyKey
    }

    fun hasKey(): Boolean = load().isNotBlank()

    fun save(apiKey: String) {
        val trimmed = apiKey.trim()
        if (trimmed.isEmpty()) {
            clear()
            return
        }

        encrypt(trimmed)?.let { encrypted ->
            settings.edit()
                .putString(GEMINI_API_KEY_CIPHER, encrypted.cipherText)
                .putString(GEMINI_API_KEY_IV, encrypted.iv)
                .remove(GEMINI_API_KEY_LEGACY)
                .apply()
        }
    }

    fun clear() {
        settings.edit()
            .remove(GEMINI_API_KEY_CIPHER)
            .remove(GEMINI_API_KEY_IV)
            .remove(GEMINI_API_KEY_LEGACY)
            .apply()
    }

    private fun encrypt(value: String): EncryptedValue? = runCatching {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val cipherText = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        EncryptedValue(
            cipherText = Base64.encodeToString(cipherText, Base64.NO_WRAP),
            iv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
        )
    }.getOrNull()

    private fun decrypt(cipherText: String, iv: String): String? = runCatching {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val ivBytes = Base64.decode(iv, Base64.NO_WRAP)
        cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, ivBytes))
        val plainText = cipher.doFinal(Base64.decode(cipherText, Base64.NO_WRAP))
        String(plainText, Charsets.UTF_8).trim()
    }.getOrNull()

    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val existingKey = keyStore.getEntry(GEMINI_KEY_ALIAS, null) as? KeyStore.SecretKeyEntry
        if (existingKey != null) {
            return existingKey.secretKey
        }

        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        val spec = KeyGenParameterSpec.Builder(
            GEMINI_KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .build()

        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    private data class EncryptedValue(
        val cipherText: String,
        val iv: String
    )
}
