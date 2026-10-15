package com.echovault.android.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [RecordingEntity::class], version = 1, exportSchema = false)
abstract class EchoDatabase : RoomDatabase() {
    abstract fun recordingDao(): RecordingDao
    companion object {
        @Volatile private var instance: EchoDatabase? = null
        fun get(context: Context): EchoDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(context.applicationContext, EchoDatabase::class.java, "echovault.db").build().also { instance = it }
        }
    }
}
