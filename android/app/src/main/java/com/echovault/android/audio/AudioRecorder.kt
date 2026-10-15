package com.echovault.android.audio

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import java.io.File

class AudioRecorder(context: Context) {
    private val appContext = context.applicationContext
    private val stagingDir = File(appContext.cacheDir, "recording-staging").apply { mkdirs() }
    private var recorder: MediaRecorder? = null
    private var output: File? = null
    private var startedAt: Long = 0
    fun start(): File {
        check(recorder == null) { "A recording is already in progress" }
        val file = File.createTempFile("recording-", ".m4a", stagingDir)
        val next = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(appContext) else MediaRecorder()
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
