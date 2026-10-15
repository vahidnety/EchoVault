package com.echovault.android.data

import android.content.Context
import com.echovault.android.audio.AudioPlayer
import com.echovault.android.audio.AudioRecorder
import com.echovault.android.domain.Recording
import com.echovault.android.security.AudioCrypto
import java.io.File
import java.util.UUID
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class RecordingRepository(context: Context) {
    private val app = context.applicationContext
    private val dao = EchoDatabase.get(app).recordingDao()
    private val crypto = AudioCrypto()
    private val recorder = AudioRecorder(app)
    private val player = AudioPlayer()
    private val permanentDir = File(app.filesDir, "encrypted-audio").apply { mkdirs() }
    private val playbackDir = File(app.cacheDir, "playback").apply { mkdirs() }

    val recordings: Flow<List<Recording>> = dao.observeAll().map { rows -> rows.map { it.toDomain() } }

    fun startRecording(): File = recorder.start()
    suspend fun finishRecording(title: String, staging: File, durationMs: Long): Recording {
        val id = UUID.randomUUID().toString()
        val fileName = "$id.evaudio"
        val target = File(permanentDir, fileName)
        try {
            crypto.encrypt(staging.readBytes(), target)
            val recording = Recording(id, title.ifBlank { "Recording ${System.currentTimeMillis()}" }, System.currentTimeMillis(), durationMs, fileName)
            dao.upsert(RecordingEntity.from(recording))
            return recording
        } catch (t: Throwable) { target.delete(); throw t } finally { staging.delete() }
    }

    fun stopRecorder(): Pair<File, Long> = recorder.stop()
    fun cancelRecording() = recorder.cancel()

    fun play(recording: Recording, onComplete: () -> Unit, onError: (Throwable) -> Unit) {
        try {
            playbackDir.listFiles()?.forEach { it.delete() }
            val encrypted = File(permanentDir, recording.encryptedFileName)
            val plain = File.createTempFile("playback-", ".m4a", playbackDir)
            plain.writeBytes(crypto.decrypt(encrypted))
            player.play(plain, { plain.delete(); onComplete() }, { error -> plain.delete(); onError(error) })
        } catch (t: Throwable) { onError(t) }
    }

    fun stopPlayback() { player.stop(); playbackDir.listFiles()?.forEach { it.delete() } }
    suspend fun delete(recording: Recording) {
        stopPlayback()
        File(permanentDir, recording.encryptedFileName).delete()
        dao.delete(recording.id)
    }
    suspend fun saveTranscript(recording: Recording, transcript: String) = dao.updateTranscript(recording.id, transcript)
    fun availableAudioFiles(): List<File> = permanentDir.listFiles()?.toList().orEmpty()
}
