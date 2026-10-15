package com.echovault.android

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.echovault.android.data.RecordingRepository
import com.echovault.android.domain.Recording
import com.echovault.android.transcription.OnDeviceTranscriber
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.text.DateFormat
import java.util.Date

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val factory = remember { EchoViewModel.Factory(RecordingRepository(applicationContext), OnDeviceTranscriber(applicationContext)) }
            val vm: EchoViewModel = viewModel(factory = factory)
            MaterialTheme(colorScheme = lightColorScheme(primary = Color(0xFF5556D1), background = Color(0xFFF7F7FC))) { EchoVaultScreen(vm) }
        }
    }
}

class EchoViewModel(private val repository: RecordingRepository, private val transcriber: OnDeviceTranscriber) : ViewModel() {
    val recordings = repository.recordings.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
    var query by mutableStateOf(""); private set
    var recording by mutableStateOf(false); private set
    var status by mutableStateOf("Your audio stays encrypted on this device."); private set
    var activeStaging by mutableStateOf<File?>(null); private set
    var playingId by mutableStateOf<String?>(null); private set
    fun updateQuery(value: String) { query = value }
    fun start() {
        try { activeStaging = repository.startRecording(); recording = true; status = "Recording…" }
        catch (t: Throwable) { status = "Could not start recording: ${t.message ?: "unknown error"}" }
    }
    fun stop() { viewModelScope.launch {
        if (activeStaging == null) return@launch
        try {
            val (staging, duration) = repository.stopRecorder()
            repository.finishRecording("Recording ${DateFormat.getTimeInstance(DateFormat.SHORT).format(Date())}", staging, duration)
            status = "Recording saved and encrypted."
        } catch (t: Throwable) { repository.cancelRecording(); status = "Could not save recording: ${t.message ?: "unknown error"}" }
        finally { activeStaging = null; recording = false }
    } }
    fun cancel() { repository.cancelRecording(); activeStaging = null; recording = false; status = "Recording discarded." }
    fun play(item: Recording) {
        playingId = item.id; status = "Preparing secure playback…"
        repository.play(item, { playingId = null; status = "Playback finished." }, { playingId = null; status = "Playback error: ${it.message ?: "unknown error"}" })
    }
    fun delete(item: Recording) { viewModelScope.launch { runCatching { repository.delete(item) }.onSuccess { status = "Recording deleted." }.onFailure { status = "Could not delete recording: ${it.message}" } } }
    fun transcribe() { status = if (transcriber.isAvailable()) "On-device speech recognition is available, but this starter does not transcribe saved recordings." else "On-device transcription is unavailable on this device. No online fallback will be used." }
    override fun onCleared() { repository.stopPlayback(); if (recording) repository.cancelRecording(); super.onCleared() }
    class Factory(private val repo: RecordingRepository, private val transcriber: OnDeviceTranscriber) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST") override fun <T : ViewModel> create(modelClass: Class<T>): T = EchoViewModel(repo, transcriber) as T
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable private fun EchoVaultScreen(vm: EchoViewModel) {
    val context = LocalContext.current
    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted -> if (granted) vm.start() }
    val recordings by vm.recordings.collectAsState()
    val filtered = recordings.filter { it.title.contains(vm.query, true) || it.transcript.orEmpty().contains(vm.query, true) }
    Scaffold(topBar = { TopAppBar(title = { Column { Text("EchoVault", fontWeight = FontWeight.Bold); Text("Private audio journal", style = MaterialTheme.typography.labelMedium) } }) }) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).padding(horizontal = 18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Card(shape = RoundedCornerShape(24.dp), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Capture what matters.", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    Text("Recordings are encrypted before they are saved to your private app storage.", style = MaterialTheme.typography.bodyMedium)
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Button(onClick = { if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) vm.start() else permission.launch(Manifest.permission.RECORD_AUDIO) }, enabled = !vm.recording) { Icon(Icons.Default.Mic, null); Spacer(Modifier.width(6.dp)); Text("Record") }
                        Button(onClick = vm::stop, enabled = vm.recording) { Icon(Icons.Default.Stop, null); Spacer(Modifier.width(6.dp)); Text("Save") }
                        if (vm.recording) TextButton(onClick = vm::cancel) { Text("Discard") }
                    }
                    Text(vm.status, style = MaterialTheme.typography.bodySmall)
                }
            }
            OutlinedTextField(value = vm.query, onValueChange = vm::updateQuery, modifier = Modifier.fillMaxWidth(), placeholder = { Text("Search recordings and transcripts") }, leadingIcon = { Icon(Icons.Default.Search, null) }, singleLine = true)
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) { Text("Your library", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold); Spacer(Modifier.weight(1f)); Text("${filtered.size} items", style = MaterialTheme.typography.labelMedium) }
            if (filtered.isEmpty()) {
                Box(Modifier.fillMaxWidth().weight(1f), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Icon(Icons.Default.Mic, null, modifier = Modifier.size(42.dp), tint = MaterialTheme.colorScheme.primary)
                        Text(if (vm.query.isBlank()) "No recordings yet" else "No matching recordings", fontWeight = FontWeight.SemiBold)
                        Text("Your recordings will appear here.", style = MaterialTheme.typography.bodySmall)
                    }
                }
            } else LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(10.dp), contentPadding = PaddingValues(bottom = 18.dp)) {
                items(filtered, key = { it.id }) { item -> RecordingCard(item, isPlaying = vm.playingId == item.id, onPlay = { vm.play(item) }, onDelete = { vm.delete(item) }) }
            }
        }
    }
}

@Composable private fun RecordingCard(item: Recording, isPlaying: Boolean, onPlay: () -> Unit, onDelete: () -> Unit) {
    Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(18.dp), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Surface(shape = RoundedCornerShape(12.dp), color = MaterialTheme.colorScheme.secondaryContainer) { Icon(Icons.Default.Mic, null, Modifier.padding(12.dp), tint = MaterialTheme.colorScheme.primary) }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(item.title, fontWeight = FontWeight.SemiBold, maxLines = 1)
                Text(DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT).format(Date(item.createdAtEpochMs)), style = MaterialTheme.typography.labelSmall)
                Text("${item.durationMs / 1000}s · AES-GCM encrypted", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                item.transcript?.takeIf { it.isNotBlank() }?.let { Text(it, style = MaterialTheme.typography.bodySmall, maxLines = 2) }
            }
            IconButton(onClick = onPlay) { Icon(Icons.Default.PlayArrow, contentDescription = if (isPlaying) "Playing" else "Play") }
            IconButton(onClick = onDelete) { Icon(Icons.Default.Delete, contentDescription = "Delete recording") }
        }
    }
}
