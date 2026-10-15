package com.echovault.android.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.echovault.android.domain.Recording

@Entity(tableName = "recordings")
data class RecordingEntity(
    @PrimaryKey val id: String,
    val title: String,
    val createdAtEpochMs: Long,
    val durationMs: Long,
    val encryptedFileName: String,
    val transcript: String?
) {
    fun toDomain() = Recording(id, title, createdAtEpochMs, durationMs, encryptedFileName, transcript)
    companion object { fun from(r: Recording) = RecordingEntity(r.id, r.title, r.createdAtEpochMs, r.durationMs, r.encryptedFileName, r.transcript) }
}
