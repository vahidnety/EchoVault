package com.echovault.android.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class RecordingTest {
    @Test fun recordingMetadataKeepsValues() {
        val recording = Recording("id", "Interview", 100L, 2500L, "id.evaudio", "hello")
        assertEquals("Interview", recording.title)
        assertEquals(2500L, recording.durationMs)
        assertEquals("hello", recording.transcript)
    }
}
