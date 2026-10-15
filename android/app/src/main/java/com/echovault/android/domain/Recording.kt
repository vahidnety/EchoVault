package com.echovault.android.domain

/** Metadata only. Audio bytes remain encrypted on disk and are never stored in the database. */
data class Recording(
    val id: String,
    val title: String,
    val createdAtEpochMs: Long,
    val durationMs: Long,
    val encryptedFileName: String,
    val transcript: String? = null
)
