package com.echovault.android.audio

import android.content.Context
import android.media.MediaRecorder
import java.io.File

class AudioRecorder(context: Context) {
    private val stagingDir = File(context.cacheDir, "recording-staging").apply { mkdirs() }
    private var recorder: MediaRecorder? = null
    private var output: File? = null
    private var startedAt: Long = 0

    fun start(): File {
        check(recorder == null) { "A recording is already in progress" }
        val file = File.createTempFile("recording-", ".m4a", stagingDir)
        val next = if (android.os.Build.VERSION.SDK_INT >= 31) MediaRecorder(file.contextCompatNoop()) else MediaRecorder()
        try {
            next.setAudioSource(MediaRecorder.AudioSource.MIC)
            next.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            next.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            next.setAudioSamplingRate(44100)
            next.setAudioChannels(1)
            next.setOutputFile(file.absolutePath)
            next.prepare()
            next.start()
            recorder = next; output = file; startedAt = System.currentTimeMillis()
            return file
        } catch (t: Throwable) { runCatching { next.release() }; file.delete(); throw t }
    }
    fun stop(): Pair<File, Long> {
        val active = recorder ?: error("No active recording")
        val file = output ?: error("No recording file")
        try { active.stop() } finally { active.release(); recorder = null; output = null }
        return file to (System.currentTimeMillis() - startedAt).coerceAtLeast(0)
    }
    fun cancel() { runCatching { recorder?.stop() }; runCatching { recorder?.release() }; recorder = null; output?.delete(); output = null }
}

// Avoid API-specific constructor divergence while keeping a single recording path.
private fun File.contextCompatNoop(): android.content.Context = throw UnsupportedOperationException("Context required")
