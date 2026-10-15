package com.echovault.android.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao interface RecordingDao {
    @Query("SELECT * FROM recordings ORDER BY createdAtEpochMs DESC") fun observeAll(): Flow<List<RecordingEntity>>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(entity: RecordingEntity)
    @Query("DELETE FROM recordings WHERE id = :id") suspend fun delete(id: String)
    @Query("UPDATE recordings SET transcript = :transcript WHERE id = :id") suspend fun updateTranscript(id: String, transcript: String)
}
