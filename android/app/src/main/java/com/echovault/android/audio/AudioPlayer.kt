package com.echovault.android.audio

import android.media.MediaPlayer
import java.io.File

class AudioPlayer {
    private var player: MediaPlayer? = null
    fun play(file: File, onComplete: () -> Unit, onError: (Throwable) -> Unit) {
        stop()
        try {
            val next = MediaPlayer()
            player = next
            next.setOnCompletionListener { stop(); onComplete() }
            next.setOnErrorListener { _, what, extra -> stop(); onError(IllegalStateException("Playback failed ($what/$extra)")); true }
            next.setDataSource(file.absolutePath)
            next.prepare()
            next.start()
        } catch (t: Throwable) { stop(); onError(t) }
    }
    fun stop() { runCatching { player?.stop() }; runCatching { player?.release() }; player = null }
}
