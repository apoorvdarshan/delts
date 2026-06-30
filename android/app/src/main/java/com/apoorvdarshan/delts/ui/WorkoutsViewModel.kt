package com.apoorvdarshan.delts.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.apoorvdarshan.delts.data.ExerciseSort

/** Holds the Workouts library filter/sort/search state, mirroring the iOS browser. */
class WorkoutsViewModel : ViewModel() {
    var search by mutableStateOf("")
    var levels by mutableStateOf<Set<String>>(emptySet())
    var equipment by mutableStateOf<Set<String>>(emptySet())
    var primaryMuscles by mutableStateOf<Set<String>>(emptySet())
    var secondaryMuscles by mutableStateOf<Set<String>>(emptySet())
    var forces by mutableStateOf<Set<String>>(emptySet())
    var mechanics by mutableStateOf<Set<String>>(emptySet())
    var categories by mutableStateOf<Set<String>>(emptySet())
    var sort by mutableStateOf(ExerciseSort.NAME)

    /** Currently open exercise (by id), or null for the list. */
    var openExerciseId by mutableStateOf<String?>(null)

    val hasActiveFilters: Boolean
        get() = search.isNotEmpty() ||
            levels.isNotEmpty() ||
            equipment.isNotEmpty() ||
            primaryMuscles.isNotEmpty() ||
            secondaryMuscles.isNotEmpty() ||
            forces.isNotEmpty() ||
            mechanics.isNotEmpty() ||
            categories.isNotEmpty() ||
            sort != ExerciseSort.NAME

    fun reset() {
        search = ""
        levels = emptySet()
        equipment = emptySet()
        primaryMuscles = emptySet()
        secondaryMuscles = emptySet()
        forces = emptySet()
        mechanics = emptySet()
        categories = emptySet()
        sort = ExerciseSort.NAME
    }
}
