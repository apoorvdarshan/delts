package com.apoorvdarshan.delts

import android.content.SharedPreferences
import android.content.res.AssetManager
import android.graphics.BitmapFactory
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.annotation.DrawableRes
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.VpnKey
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DividerDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.apoorvdarshan.delts.ui.theme.DeltsAccent
import com.apoorvdarshan.delts.ui.theme.DeltsOnAccent
import com.apoorvdarshan.delts.ui.theme.DeltsSecondaryAccent
import com.apoorvdarshan.delts.ui.theme.DeltsTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import kotlinx.coroutines.delay
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.roundToInt

private const val SETTINGS_NAME = "delts_settings"
private val metricDateFormatter = SimpleDateFormat("MMM d, h:mm a", Locale.US)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val settings = getSharedPreferences(SETTINGS_NAME, MODE_PRIVATE)

        enableEdgeToEdge()
        setContent {
            DeltsTheme {
                DeltsAndroidApp(settings = settings)
            }
        }
    }
}

@Composable
private fun DeltsAndroidApp(settings: SharedPreferences) {
    val context = LocalContext.current
    var selectedTab by rememberSaveable { mutableStateOf(DeltsTab.Start) }
    var profile by remember { mutableStateOf(settings.loadProfile()) }
    var measurementSystem by rememberSaveable { mutableStateOf(settings.loadMeasurementSystem()) }
    var aiSettings by remember { mutableStateOf(settings.loadAISettings()) }
    var workoutHistory by remember { mutableStateOf(settings.loadWorkoutHistory()) }
    var metricSnapshots by remember { mutableStateOf(settings.recordMetricSnapshot(profile)) }
    val keyStore = remember(settings) { GeminiKeyStore(settings) }
    val fallbackKeyStore = remember(settings) { GeminiKeyStore(settings, "ai_fallback_api_key") }
    val exerciseLibrary = remember(context) { loadFreeExerciseDB(context.assets) }

    fun updateProfile(updatedProfile: AndroidProfile) {
        profile = updatedProfile
        settings.saveProfile(updatedProfile)
        metricSnapshots = settings.recordMetricSnapshot(updatedProfile)
    }

    fun updateMeasurementSystem(updatedSystem: MeasurementSystem) {
        measurementSystem = updatedSystem
        settings.saveMeasurementSystem(updatedSystem)
    }

    fun updateAISettings(updatedSettings: AISettings) {
        val normalizedSettings = updatedSettings.normalized()
        aiSettings = normalizedSettings
        settings.saveAISettings(normalizedSettings)
    }

    fun saveCompletedWorkout(record: WorkoutHistoryRecord) {
        workoutHistory = (listOf(record) + workoutHistory).take(200)
        settings.saveWorkoutHistory(workoutHistory)
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        bottomBar = {
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.96f),
                tonalElevation = 0.dp
            ) {
                DeltsTab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = selectedTab == tab,
                        onClick = { selectedTab = tab },
                        icon = { Icon(tab.icon, contentDescription = null) },
                        label = { Text(tab.title) }
                    )
                }
            }
        }
    ) { padding ->
        DeltsScreenBackground {
            when (selectedTab) {
                DeltsTab.Start -> StartScreen(
                    profile = profile,
                    exerciseLibrary = exerciseLibrary,
                    settings = settings,
                    onWorkoutCompleted = ::saveCompletedWorkout,
                    padding = padding
                )
                DeltsTab.Workouts -> WorkoutsScreen(
                    profile = profile,
                    exerciseLibrary = exerciseLibrary,
                    padding = padding
                )
                DeltsTab.Progress -> ProgressScreen(
                    profile = profile,
                    measurementSystem = measurementSystem,
                    snapshots = metricSnapshots,
                    workouts = workoutHistory,
                    onSnapshotsChange = { updated ->
                        metricSnapshots = updated.sortedBy { it.dateMs }
                        settings.saveMetricSnapshots(metricSnapshots)
                    },
                    onProgressProfileChange = { weightKg, bodyFat ->
                        val updatedProfile = profile.copy(weightKg = weightKg, currentBodyFat = bodyFat)
                        profile = updatedProfile
                        settings.saveProfile(updatedProfile)
                    },
                    padding = padding
                )
                DeltsTab.Profile -> ProfileScreen(
                    profile = profile,
                    updateProfile = ::updateProfile,
                    exerciseLibrary = exerciseLibrary,
                    measurementSystem = measurementSystem,
                    updateMeasurementSystem = ::updateMeasurementSystem,
                    aiSettings = aiSettings,
                    updateAISettings = ::updateAISettings,
                    keyStore = keyStore,
                    fallbackKeyStore = fallbackKeyStore,
                    padding = padding
                )
            }
        }
    }
}

@Composable
private fun StartScreen(
    profile: AndroidProfile,
    exerciseLibrary: List<ExerciseItem>,
    settings: SharedPreferences? = null,
    onWorkoutCompleted: (WorkoutHistoryRecord) -> Unit = {},
    padding: PaddingValues
) {
    var routineDays by remember(settings) { mutableStateOf(settings?.loadWeeklyRoutine() ?: defaultRoutineDays) }
    var selectedDayIndex by rememberSaveable { mutableStateOf(todayRoutineIndex()) }
    var search by rememberSaveable { mutableStateOf("") }
    var activeSession by remember { mutableStateOf<ActiveWorkoutSession?>(null) }
    var nowMs by remember { mutableStateOf(System.currentTimeMillis()) }

    LaunchedEffect(activeSession?.startedAtMs) {
        while (activeSession != null) {
            nowMs = System.currentTimeMillis()
            delay(1000)
        }
    }

    val selectedDay = routineDays.getOrElse(selectedDayIndex) { defaultRoutineDays.first() }
    val bodyPartOptions = remember(exerciseLibrary) { exerciseLibrary.flatMap { it.primaryMuscles }.distinctSorted() }
    val matchingItems = remember(selectedDay.bodyPart, search, exerciseLibrary) {
        exerciseLibrary.filter { item ->
            (selectedDay.bodyPart == anyRoutineBodyPart || item.primaryMuscles.contains(selectedDay.bodyPart)) &&
                (search.isBlank() || item.name.contains(search, ignoreCase = true))
        }
    }

    fun updateSelectedDay(transform: (RoutineDay) -> RoutineDay) {
        routineDays = routineDays.mapIndexed { index, day ->
            if (index == selectedDayIndex) transform(day) else day
        }
        settings?.saveWeeklyRoutine(routineDays)
    }

    fun addExercise(item: ExerciseItem) {
        updateSelectedDay { day ->
            day.copy(exercises = day.exercises + RoutineExercise.from(item))
        }
    }

    fun updateExercise(exerciseId: String, transform: (RoutineExercise) -> RoutineExercise) {
        updateSelectedDay { day ->
            day.copy(exercises = day.exercises.map { exercise ->
                if (exercise.id == exerciseId) transform(exercise) else exercise
            })
        }
    }

    fun removeExercise(exerciseId: String) {
        updateSelectedDay { day ->
            day.copy(exercises = day.exercises.filterNot { it.id == exerciseId })
        }
    }

    activeSession?.let { session ->
        ActiveRoutineScreen(
            session = session,
            nowMs = nowMs,
            onSessionChange = { activeSession = it },
            onFinish = {
                val finishedAt = System.currentTimeMillis()
                onWorkoutCompleted(session.toHistoryRecord(finishedAt))
                activeSession = null
            },
            padding = padding
        )
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 12.dp, bottom = 118.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        PlannerOverview()

        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            routineDays.forEachIndexed { index, day ->
                RoutineDayRow(
                    day = day,
                    selected = selectedDayIndex == index,
                    onClick = { selectedDayIndex = index }
                )

                if (selectedDayIndex == index) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(20.dp))
                            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.22f))
                            .padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        HorizontalChipRail {
                            DeltsPillButton(
                                title = anyRoutineBodyPart,
                                icon = Icons.Filled.FitnessCenter,
                                selected = selectedDay.bodyPart == anyRoutineBodyPart
                            ) {
                                updateSelectedDay { it.copy(bodyPart = anyRoutineBodyPart) }
                            }
                            bodyPartOptions.forEach { muscle ->
                                DeltsPillButton(
                                    title = muscle,
                                    icon = Icons.Filled.FitnessCenter,
                                    selected = selectedDay.bodyPart == muscle
                                ) {
                                    updateSelectedDay { it.copy(bodyPart = muscle) }
                                }
                            }
                        }

                        LibrarySearchPill(search = search, onSearchChange = { search = it })

                        var expanded by rememberSaveable { mutableStateOf(false) }
                        Box {
                            Button(
                                onClick = { expanded = true },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(52.dp),
                                shape = RoundedCornerShape(18.dp),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.52f),
                                    contentColor = MaterialTheme.colorScheme.onBackground
                                )
                            ) {
                                Icon(Icons.Filled.Add, contentDescription = null)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Add Workout", fontWeight = FontWeight.Bold)
                            }
                            DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }, modifier = Modifier.heightIn(max = 420.dp)) {
                                matchingItems.take(80).forEach { item ->
                                    DropdownMenuItem(
                                        text = { Text(item.name, maxLines = 2, overflow = TextOverflow.Ellipsis) },
                                        onClick = {
                                            addExercise(item)
                                            expanded = false
                                        }
                                    )
                                }
                            }
                        }

                        if (selectedDay.exercises.isEmpty()) {
                            EmptyRoutineCard()
                        } else {
                            selectedDay.exercises.forEach { exercise ->
                                RoutineExerciseRow(
                                    exercise = exercise,
                                    onSetsChange = { sets -> updateExercise(exercise.id) { it.copy(sets = sets) } },
                                    onRepsChange = { reps -> updateExercise(exercise.id) { it.copy(reps = reps) } },
                                    onRemove = { removeExercise(exercise.id) }
                                )
                            }
                        }
                    }
                }
            }
        }

        Button(
            onClick = {
                activeSession = ActiveWorkoutSession.from(
                    title = "${selectedDay.name} ${selectedDay.bodyPart}",
                    bodyPart = selectedDay.bodyPart,
                    exercises = selectedDay.exercises,
                    startedAtMs = System.currentTimeMillis()
                )
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp),
            shape = RoundedCornerShape(27.dp),
            enabled = selectedDay.exercises.isNotEmpty(),
            colors = ButtonDefaults.buttonColors(
                containerColor = DeltsAccent,
                contentColor = DeltsOnAccent
            )
        ) {
            Icon(Icons.Filled.PlayArrow, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text(if (selectedDay.exercises.isEmpty()) "Add Workout To Start" else "Start ${selectedDay.name}", fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun PlannerOverview() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 2.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "WORKOUT PLANNER",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.ExtraBold,
            color = DeltsAccent,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier
                .weight(1f)
                .height(48.dp)
                .wrapContentHeight(Alignment.CenterVertically)
        )
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(DeltsAccent.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.CalendarToday, contentDescription = null, tint = DeltsAccent)
        }
    }
}

@Composable
private fun RoutineDayRow(day: RoutineDay, selected: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(if (selected) DeltsAccent else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.38f))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = day.shortName,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.ExtraBold,
            color = if (selected) DeltsOnAccent else MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.width(46.dp)
        )
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = day.bodyPart,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = if (selected) DeltsOnAccent else MaterialTheme.colorScheme.onBackground,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "${day.exercises.size} ${if (day.exercises.size == 1) "workout" else "workouts"}",
                style = MaterialTheme.typography.labelLarge,
                color = if (selected) DeltsOnAccent.copy(alpha = 0.72f) else MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1
            )
        }
        Icon(
            imageVector = if (selected) Icons.Filled.Check else Icons.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = if (selected) DeltsOnAccent else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun EmptyRoutineCard() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.38f))
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Filled.CalendarToday, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(28.dp))
        Text(
            text = "Add a dataset workout to this day.",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
    }
}

@Composable
private fun RoutineExerciseRow(
    exercise: RoutineExercise,
    onSetsChange: (Int) -> Unit,
    onRepsChange: (String) -> Unit,
    onRemove: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.28f))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            ExerciseVisual(
                imagePaths = exercise.imagePaths,
                fallbackIcon = Icons.Filled.FitnessCenter,
                modifier = Modifier.size(62.dp),
                cornerRadius = 16,
                iconSize = 28
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = exercise.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onBackground,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "${exercise.primaryMuscles.ifEmpty { listOf("Unspecified") }.joinToString(", ")} - ${exercise.rawEquipment} - ${exercise.level}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Icon(
                Icons.Filled.Close,
                contentDescription = "Remove",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier
                    .size(28.dp)
                    .clickable(onClick = onRemove)
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            DeltsPillButton(
                title = "-",
                icon = Icons.Filled.Close,
                selected = false,
                modifier = Modifier.width(54.dp)
            ) {
                onSetsChange((exercise.sets - 1).coerceAtLeast(1))
            }
            Text(
                text = "${exercise.sets.coerceAtLeast(1)} ${if (exercise.sets == 1) "set" else "sets"}",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Center
            )
            DeltsPillButton(
                title = "+",
                icon = Icons.Filled.Add,
                selected = false,
                modifier = Modifier.width(54.dp)
            ) {
                onSetsChange((exercise.sets + 1).coerceAtMost(12))
            }
            OutlinedTextField(
                value = exercise.reps,
                onValueChange = onRepsChange,
                modifier = Modifier.width(92.dp),
                singleLine = true,
                label = { Text("Reps") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
            )
        }
    }
}

@Composable
private fun ActiveRoutineScreen(
    session: ActiveWorkoutSession,
    nowMs: Long,
    onSessionChange: (ActiveWorkoutSession) -> Unit,
    onFinish: () -> Unit,
    padding: PaddingValues
) {
    fun updateSet(exerciseId: String, setNumber: Int, transform: (ActiveSetLog) -> ActiveSetLog) {
        onSessionChange(
            session.copy(
                exercises = session.exercises.map { exercise ->
                    if (exercise.id != exerciseId) {
                        exercise
                    } else {
                        exercise.copy(sets = exercise.sets.map { set ->
                            if (set.setNumber == setNumber) transform(set) else set
                        })
                    }
                }
            )
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 12.dp, bottom = 118.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        session.exercises.forEach { exercise ->
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(22.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.24f))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    ExerciseVisual(
                        imagePaths = exercise.imagePaths,
                        fallbackIcon = Icons.Filled.FitnessCenter,
                        modifier = Modifier.size(70.dp),
                        cornerRadius = 18,
                        iconSize = 30
                    )
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = exercise.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onBackground,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = "${exercise.primaryMuscles.ifEmpty { listOf("Unspecified") }.joinToString(", ")} - ${exercise.rawEquipment}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                exercise.sets.forEach { set ->
                    ActiveSetRow(
                        set = set,
                        onWeightChange = { value -> updateSet(exercise.id, set.setNumber) { it.copy(weight = value) } },
                        onRepsChange = { value -> updateSet(exercise.id, set.setNumber) { it.copy(reps = value) } },
                        onToggleComplete = {
                            val elapsed = ((nowMs - session.startedAtMs) / 1000).toInt().coerceAtLeast(0)
                            updateSet(exercise.id, set.setNumber) {
                                if (it.completed) {
                                    it.copy(completed = false, elapsedSeconds = null)
                                } else {
                                    it.copy(completed = true, elapsedSeconds = elapsed)
                                }
                            }
                        }
                    )
                }
            }
        }

        Button(
            onClick = onFinish,
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp),
            shape = RoundedCornerShape(27.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DeltsAccent, contentColor = DeltsOnAccent)
        ) {
            Icon(Icons.Filled.Check, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("End Workout", fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun ActiveSetRow(
    set: ActiveSetLog,
    onWeightChange: (String) -> Unit,
    onRepsChange: (String) -> Unit,
    onToggleComplete: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(if (set.completed) DeltsSecondaryAccent.copy(alpha = 0.10f) else MaterialTheme.colorScheme.surface.copy(alpha = 0.36f))
            .padding(10.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.width(44.dp)) {
            Text(
                text = set.setNumber.toString(),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground
            )
            set.elapsedSeconds?.let {
                Text(
                    text = elapsedDisplay(it),
                    style = MaterialTheme.typography.labelSmall,
                    color = DeltsSecondaryAccent,
                    maxLines = 1
                )
            }
        }
        OutlinedTextField(
            value = set.weight,
            onValueChange = onWeightChange,
            modifier = Modifier.weight(1f),
            singleLine = true,
            label = { Text("Weight") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
        )
        OutlinedTextField(
            value = set.reps,
            onValueChange = onRepsChange,
            modifier = Modifier.width(86.dp),
            singleLine = true,
            label = { Text("Reps") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
        )
        Icon(
            imageVector = if (set.completed) Icons.Filled.Check else Icons.Filled.Add,
            contentDescription = null,
            tint = if (set.completed) DeltsSecondaryAccent else MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier
                .size(34.dp)
                .clickable(onClick = onToggleComplete)
        )
    }
}

@Composable
private fun WorkoutsScreen(
    profile: AndroidProfile,
    exerciseLibrary: List<ExerciseItem>,
    padding: PaddingValues
) {
    var selectedSplitGroupTitle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedLevel by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedRawEquipment by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedPrimaryMuscle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedSecondaryMuscle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedForce by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedMechanic by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedCategory by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedSort by rememberSaveable { mutableStateOf(LibrarySort.Name) }
    var search by rememberSaveable { mutableStateOf("") }
    var selectedExerciseName by rememberSaveable { mutableStateOf<String?>(null) }

    val levelOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.level }.distinctSortedLevels() }
    val rawEquipmentOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.rawEquipment }.distinctSorted() }
    val primaryMuscleOptions = remember(exerciseLibrary) { exerciseLibrary.flatMap { it.primaryMuscles }.distinctSorted() }
    val secondaryMuscleOptions = remember(exerciseLibrary) { exerciseLibrary.flatMap { it.secondaryMuscles }.distinctSorted() }
    val forceOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.force }.distinctSorted() }
    val mechanicOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.mechanic }.distinctSorted() }
    val categoryCounts = remember(exerciseLibrary) { exerciseLibrary.groupingBy { it.category }.eachCount() }
    val categoryOptions = remember(categoryCounts) {
        categoryCounts.entries
            .sortedWith(
                compareByDescending<Map.Entry<String, Int>> { it.value }
                    .thenBy(String.CASE_INSENSITIVE_ORDER) { it.key }
            )
            .map { it.key }
    }
    val splitMuscleGroups = remember(profile.workoutSplit) { splitMuscleGroupsFor(profile.workoutSplit) }
    val selectedSplitGroup = remember(selectedSplitGroupTitle, splitMuscleGroups) {
        splitMuscleGroups.firstOrNull { it.title == selectedSplitGroupTitle }
    }

    LaunchedEffect(profile.workoutSplit) {
        selectedSplitGroupTitle = null
    }

    val hasActiveFilters =
        selectedSplitGroup != null ||
            selectedLevel != null ||
            selectedRawEquipment != null ||
            selectedPrimaryMuscle != null ||
            selectedSecondaryMuscle != null ||
            selectedForce != null ||
            selectedMechanic != null ||
            selectedCategory != null ||
            selectedSort != LibrarySort.Name ||
            search.isNotBlank()

    fun resetLibraryFilters() {
        selectedSplitGroupTitle = null
        selectedLevel = null
        selectedRawEquipment = null
        selectedPrimaryMuscle = null
        selectedSecondaryMuscle = null
        selectedForce = null
        selectedMechanic = null
        selectedCategory = null
        selectedSort = LibrarySort.Name
        search = ""
    }

    fun selectedCategoryTitle(): String =
        selectedCategory ?: "All"

    val selectedExercise = remember(selectedExerciseName, exerciseLibrary) {
        selectedExerciseName?.let { name -> exerciseLibrary.firstOrNull { it.name == name } }
    }
    if (selectedExercise != null) {
        ExerciseLibraryDetailScreen(
            item = selectedExercise,
            padding = padding,
            onBack = { selectedExerciseName = null }
        )
        return
    }

    val filteredExercises = remember(
        selectedLevel,
        selectedRawEquipment,
        selectedSplitGroup,
        selectedPrimaryMuscle,
        selectedSecondaryMuscle,
        selectedForce,
        selectedMechanic,
        selectedCategory,
        selectedSort,
        search,
        exerciseLibrary
    ) {
        val query = search.trim().lowercase(Locale.US)
        exerciseLibrary
            .filter { item ->
                    (selectedLevel == null || item.level == selectedLevel) &&
                    (selectedRawEquipment == null || item.rawEquipment == selectedRawEquipment) &&
                    (selectedSplitGroup?.let { group -> item.primaryMuscles.any { group.muscles.contains(it) } } ?: true) &&
                    (selectedPrimaryMuscle?.let { item.primaryMuscles.contains(it) } ?: true) &&
                    (selectedSecondaryMuscle?.let { item.secondaryMuscles.contains(it) } ?: true) &&
                    (selectedForce == null || item.force == selectedForce) &&
                    (selectedMechanic == null || item.mechanic == selectedMechanic) &&
                    (selectedCategory == null || item.category == selectedCategory) &&
                    (query.isBlank() || item.searchableText().contains(query))
            }
            .sortedWith(selectedSort.comparator())
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .padding(horizontal = 20.dp),
        contentPadding = PaddingValues(top = 16.dp, bottom = 112.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                LibrarySearchPill(
                    search = search,
                    onSearchChange = { search = it },
                    modifier = Modifier.fillMaxWidth()
                )

                HorizontalChipRail {
                    if (splitMuscleGroups.isNotEmpty()) {
                        LibraryFilterMenu(
                            title = profile.workoutSplit,
                            value = selectedSplitGroup?.title ?: "All",
                            icon = Icons.Filled.Home,
                            active = selectedSplitGroup != null,
                            options = splitMuscleGroups.map { it.title },
                            selectedOption = selectedSplitGroupTitle,
                            allTitle = "All ${profile.workoutSplit}"
                        ) {
                            selectedSplitGroupTitle = it
                        }
                    }
                    LibraryFilterMenu(
                        title = "Primary",
                        value = selectedPrimaryMuscle ?: "All",
                        icon = Icons.Filled.FitnessCenter,
                        active = selectedPrimaryMuscle != null,
                        options = primaryMuscleOptions,
                        selectedOption = selectedPrimaryMuscle,
                        allTitle = "All Primary"
                    ) {
                        selectedPrimaryMuscle = it
                    }
                    LibraryFilterMenu(
                        title = "Secondary",
                        value = selectedSecondaryMuscle ?: "All",
                        icon = Icons.Filled.FitnessCenter,
                        active = selectedSecondaryMuscle != null,
                        options = secondaryMuscleOptions,
                        selectedOption = selectedSecondaryMuscle,
                        allTitle = "All Secondary"
                    ) {
                        selectedSecondaryMuscle = it
                    }
                    LibraryFilterMenu(
                        title = "Equipment",
                        value = selectedRawEquipment ?: "All",
                        icon = Icons.Filled.Build,
                        active = selectedRawEquipment != null,
                        options = rawEquipmentOptions,
                        selectedOption = selectedRawEquipment,
                        allTitle = "All Equipment"
                    ) { selectedRawEquipment = it }
                    LibraryFilterMenu(
                        title = "Level",
                        value = selectedLevel ?: "All",
                        icon = Icons.Filled.FlashOn,
                        active = selectedLevel != null,
                        options = levelOptions,
                        selectedOption = selectedLevel,
                        allTitle = "All Levels"
                    ) { selectedLevel = it }
                    LibraryFilterMenu(
                        title = "Sort",
                        value = selectedSort.title,
                        icon = Icons.Filled.List,
                        active = selectedSort != LibrarySort.Name,
                        options = LibrarySort.entries.filter { it != LibrarySort.Name }.map { it.title },
                        selectedOption = selectedSort.takeUnless { it == LibrarySort.Name }?.title,
                        allTitle = LibrarySort.Name.title
                    ) { selected ->
                        selectedSort = LibrarySort.entries.firstOrNull { it.title == selected } ?: LibrarySort.Name
                    }
                }

                HorizontalChipRail {
                    LibraryFilterMenu(
                        title = "Category",
                        value = selectedCategoryTitle(),
                        icon = Icons.Filled.List,
                        active = selectedCategory != null,
                        options = categoryOptions,
                        selectedOption = selectedCategory,
                        allTitle = "All Categories"
                    ) { selectedCategory = it }
                    LibraryFilterMenu(
                        title = "Force",
                        value = selectedForce ?: "All",
                        icon = Icons.Filled.Flag,
                        active = selectedForce != null,
                        options = forceOptions,
                        selectedOption = selectedForce,
                        allTitle = "All Forces"
                    ) { selectedForce = it }
                    LibraryFilterMenu(
                        title = "Mechanic",
                        value = selectedMechanic ?: "All",
                        icon = Icons.Filled.Build,
                        active = selectedMechanic != null,
                        options = mechanicOptions,
                        selectedOption = selectedMechanic,
                        allTitle = "All Mechanics"
                    ) { selectedMechanic = it }
                }
            }
        }

        item {
            ResultsHeader(
                title = "${filteredExercises.size} ${if (filteredExercises.size == 1) "exercise" else "exercises"}",
                subtitle = selectedSort.title,
                onReset = if (hasActiveFilters) {
                    { resetLibraryFilters() }
                } else {
                    null
                }
            )
        }

        items(filteredExercises, key = { it.name }) { item ->
            ExerciseLibraryRow(item = item) {
                selectedExerciseName = item.name
            }
        }
    }
}

@Composable
private fun ProgressScreen(
    profile: AndroidProfile,
    measurementSystem: MeasurementSystem,
    snapshots: List<MetricSnapshot>,
    workouts: List<WorkoutHistoryRecord>,
    onSnapshotsChange: (List<MetricSnapshot>) -> Unit,
    onProgressProfileChange: (Double, Double) -> Unit,
    padding: PaddingValues
) {
    var selectedRange by rememberSaveable { mutableStateOf(ProgressRange.Month) }
    var activeMetricDialog by rememberSaveable { mutableStateOf<MetricDialogType?>(null) }
    var editingSnapshotId by rememberSaveable { mutableStateOf<String?>(null) }
    val filteredSnapshots = remember(selectedRange, snapshots) { selectedRange.filterSnapshots(snapshots).sortedBy { it.dateMs } }
    val filteredWorkouts = remember(selectedRange, workouts) { selectedRange.filterWorkouts(workouts) }
    val usesImperial = measurementSystem == MeasurementSystem.Imperial
    val editingSnapshot = snapshots.firstOrNull { it.id == editingSnapshotId }

    fun displayWeight(kg: Double): Double = if (usesImperial) kg * 2.2046226218 else kg

    fun weightKgFromDisplay(value: Double): Double = if (usesImperial) value / 2.2046226218 else value

    fun saveMetricSnapshot(snapshot: MetricSnapshot) {
        onSnapshotsChange(upsertMetricSnapshot(snapshots, snapshot))
    }

    fun logWeight(displayValue: Double) {
        val weightKg = weightKgFromDisplay(displayValue)
        saveMetricSnapshot(MetricSnapshot(dateMs = System.currentTimeMillis(), weightKg = weightKg, bodyFat = profile.currentBodyFat))
        onProgressProfileChange(weightKg, profile.currentBodyFat)
    }

    fun logBodyFat(bodyFat: Double) {
        saveMetricSnapshot(MetricSnapshot(dateMs = System.currentTimeMillis(), weightKg = profile.weightKg, bodyFat = bodyFat))
        onProgressProfileChange(profile.weightKg, bodyFat)
    }

    fun updateMetric(snapshot: MetricSnapshot) {
        onSnapshotsChange(updateMetricSnapshot(snapshots, snapshot))
        if (snapshots.maxByOrNull { it.dateMs }?.id == snapshot.id || snapshot.dateMs >= (snapshots.maxOfOrNull { it.dateMs } ?: 0L)) {
            onProgressProfileChange(snapshot.weightKg, snapshot.bodyFat)
        }
    }

    activeMetricDialog?.let { dialogType ->
        MetricValueDialog(
            title = if (dialogType == MetricDialogType.Weight) "Log Weight" else "Log Body Fat",
            valueTitle = if (dialogType == MetricDialogType.Weight) "Weight" else "Body fat",
            initialValue = if (dialogType == MetricDialogType.Weight) displayWeight(profile.weightKg) else profile.currentBodyFat,
            unit = if (dialogType == MetricDialogType.Weight) measurementSystem.weightUnit else "%",
            onDismiss = { activeMetricDialog = null },
            onSave = { value ->
                if (dialogType == MetricDialogType.Weight) logWeight(value) else logBodyFat(value)
                activeMetricDialog = null
            }
        )
    }

    editingSnapshot?.let { snapshot ->
        MetricEditDialog(
            snapshot = snapshot,
            measurementSystem = measurementSystem,
            onDismiss = { editingSnapshotId = null },
            onSave = { updated ->
                updateMetric(updated)
                editingSnapshotId = null
            }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 12.dp, bottom = 118.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        MetricActionRow(
            onLogWeight = { activeMetricDialog = MetricDialogType.Weight },
            onLogBodyFat = { activeMetricDialog = MetricDialogType.BodyFat }
        )

        HorizontalChipRail {
            ProgressRange.entries.forEach { range ->
                DeltsPillButton(
                    title = range.title,
                    icon = Icons.Filled.History,
                    selected = selectedRange == range
                ) {
                    selectedRange = range
                }
            }
        }

        val weightPoints = filteredSnapshots.map { snapshot ->
            if (usesImperial) snapshot.weightKg * 2.2046226218 else snapshot.weightKg
        }
        val weightChangePoints = filteredSnapshots.map { snapshot ->
            snapshot.dateMs to if (usesImperial) snapshot.weightKg * 2.2046226218 else snapshot.weightKg
        }
        val bodyFatChangePoints = filteredSnapshots.map { snapshot ->
            snapshot.dateMs to snapshot.bodyFat
        }
        ProgressMetricCard(
            title = "Body Weight",
            unit = if (usesImperial) "lb" else "kg",
            values = weightPoints,
            currentValue = if (usesImperial) profile.weightKg * 2.2046226218 else profile.weightKg,
            goalValue = if (usesImperial) profile.goalWeightKg * 2.2046226218 else profile.goalWeightKg,
            averageLabel = selectedRange.title,
            averageChange = averageMetricChange(weightChangePoints, selectedRange)
        )
        ProgressMetricCard(
            title = "Body Fat",
            unit = "%",
            values = filteredSnapshots.map { it.bodyFat },
            currentValue = profile.currentBodyFat,
            goalValue = profile.desiredBodyFat,
            averageLabel = selectedRange.title,
            averageChange = averageMetricChange(bodyFatChangePoints, selectedRange)
        )

        MetricHistorySection(
            snapshots = filteredSnapshots.sortedByDescending { it.dateMs },
            measurementSystem = measurementSystem,
            onEdit = { editingSnapshotId = it.id },
            onDelete = { snapshot ->
                onSnapshotsChange(deleteMetricSnapshot(snapshots, snapshot.id))
            }
        )

        StartSection(
            title = "Workout History",
            subtitle = "${profile.displayName} - ${selectedRange.title}"
        ) {
            if (filteredWorkouts.isEmpty()) {
                Text(
                    text = "No completed workouts in this range.",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(18.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.32f))
                        .padding(16.dp)
                )
            } else {
                filteredWorkouts.forEach { workout ->
                    WorkoutHistoryCard(workout = workout)
                }
            }
        }
    }
}

@Composable
private fun MetricActionRow(onLogWeight: () -> Unit, onLogBodyFat: () -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
        MetricActionButton(
            title = "Log Weight",
            icon = Icons.Filled.FitnessCenter,
            modifier = Modifier.weight(1f),
            onClick = onLogWeight
        )
        MetricActionButton(
            title = "Log Body Fat",
            icon = Icons.Filled.Favorite,
            modifier = Modifier.weight(1f),
            onClick = onLogBodyFat
        )
    }
}

@Composable
private fun MetricActionButton(title: String, icon: ImageVector, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = modifier.height(52.dp),
        shape = RoundedCornerShape(17.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.52f),
            contentColor = MaterialTheme.colorScheme.onBackground
        )
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(19.dp))
        Spacer(modifier = Modifier.width(8.dp))
        Text(title, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

@Composable
private fun MetricHistorySection(
    snapshots: List<MetricSnapshot>,
    measurementSystem: MeasurementSystem,
    onEdit: (MetricSnapshot) -> Unit,
    onDelete: (MetricSnapshot) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            text = "Metric History",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.ExtraBold,
            color = MaterialTheme.colorScheme.onBackground
        )
        if (snapshots.isEmpty()) {
            Text(
                text = "No weight or body fat logs in this range.",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.32f))
                    .padding(16.dp)
            )
        } else {
            snapshots.forEach { snapshot ->
                MetricHistoryCard(
                    snapshot = snapshot,
                    measurementSystem = measurementSystem,
                    onEdit = { onEdit(snapshot) },
                    onDelete = { onDelete(snapshot) }
                )
            }
        }
    }
}

@Composable
private fun MetricHistoryCard(
    snapshot: MetricSnapshot,
    measurementSystem: MeasurementSystem,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    val weightDisplay = if (measurementSystem == MeasurementSystem.Imperial) snapshot.weightKg * 2.2046226218 else snapshot.weightKg
    val weightUnit = measurementSystem.weightUnit
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.26f))
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(7.dp)) {
            Text(
                text = metricDateFormatter.format(Date(snapshot.dateMs)),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                MetricHistoryPill("Weight", String.format(Locale.US, "%.1f %s", weightDisplay, weightUnit))
                MetricHistoryPill("Body fat", String.format(Locale.US, "%.1f%%", snapshot.bodyFat))
            }
        }
        TextButton(onClick = onEdit) {
            Text("Edit", fontWeight = FontWeight.Bold)
        }
        TextButton(onClick = onDelete) {
            Text("Delete", fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.error)
        }
    }
}

@Composable
private fun MetricHistoryPill(title: String, value: String) {
    Text(
        text = "$title $value",
        style = MaterialTheme.typography.labelSmall,
        fontWeight = FontWeight.Bold,
        color = DeltsSecondaryAccent,
        modifier = Modifier
            .clip(RoundedCornerShape(13.dp))
            .background(DeltsSecondaryAccent.copy(alpha = 0.10f))
            .padding(horizontal = 8.dp, vertical = 5.dp)
    )
}

@Composable
private fun MetricValueDialog(
    title: String,
    valueTitle: String,
    initialValue: Double,
    unit: String,
    onDismiss: () -> Unit,
    onSave: (Double) -> Unit
) {
    var rawValue by rememberSaveable(title) { mutableStateOf(String.format(Locale.US, "%.1f", initialValue)) }
    val parsedValue = rawValue.replace(',', '.').toDoubleOrNull()
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title, fontWeight = FontWeight.ExtraBold) },
        text = {
            OutlinedTextField(
                value = rawValue,
                onValueChange = { rawValue = it },
                label = { Text("$valueTitle ($unit)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
            )
        },
        confirmButton = {
            TextButton(enabled = parsedValue != null, onClick = { parsedValue?.let(onSave) }) {
                Text("Save", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun MetricEditDialog(
    snapshot: MetricSnapshot,
    measurementSystem: MeasurementSystem,
    onDismiss: () -> Unit,
    onSave: (MetricSnapshot) -> Unit
) {
    val displayWeight = if (measurementSystem == MeasurementSystem.Imperial) snapshot.weightKg * 2.2046226218 else snapshot.weightKg
    var weightRaw by rememberSaveable(snapshot.id) { mutableStateOf(String.format(Locale.US, "%.1f", displayWeight)) }
    var bodyFatRaw by rememberSaveable(snapshot.id) { mutableStateOf(String.format(Locale.US, "%.1f", snapshot.bodyFat)) }
    val parsedWeight = weightRaw.replace(',', '.').toDoubleOrNull()
    val parsedBodyFat = bodyFatRaw.replace(',', '.').toDoubleOrNull()
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Metric", fontWeight = FontWeight.ExtraBold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = weightRaw,
                    onValueChange = { weightRaw = it },
                    label = { Text("Weight (${measurementSystem.weightUnit})") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )
                OutlinedTextField(
                    value = bodyFatRaw,
                    onValueChange = { bodyFatRaw = it },
                    label = { Text("Body fat (%)") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )
            }
        },
        confirmButton = {
            TextButton(enabled = parsedWeight != null && parsedBodyFat != null, onClick = {
                val weightKg = if (measurementSystem == MeasurementSystem.Imperial) parsedWeight!! / 2.2046226218 else parsedWeight!!
                onSave(snapshot.copy(weightKg = weightKg, bodyFat = parsedBodyFat!!))
            }) {
                Text("Save", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun ProgressMetricCard(
    title: String,
    unit: String,
    values: List<Double>,
    currentValue: Double?,
    goalValue: Double?,
    averageLabel: String,
    averageChange: Double?
) {
    val latest = values.lastOrNull()
    val minValue = values.minOrNull() ?: 0.0
    val maxValue = values.maxOrNull() ?: 1.0
    val spread = (maxValue - minValue).takeIf { it > 0.0 } ?: 1.0

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.28f))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = if (values.size <= 1) "Current profile value" else "${values.size} entries",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (latest != null) {
                Text(
                    text = if (unit == "%") String.format(Locale.US, "%.1f%%", latest) else String.format(Locale.US, "%.1f %s", latest, unit),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.ExtraBold,
                    color = MaterialTheme.colorScheme.onBackground
                )
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            MetricStatTile("Current", currentValue?.let { formatMetricValue(it, unit) } ?: "--", Modifier.weight(1f))
            MetricStatTile("Goal", goalValue?.let { formatMetricValue(it, unit) } ?: "--", Modifier.weight(1f))
            MetricStatTile("Avg Δ / $averageLabel", averageChange?.let { formatSignedMetricValue(it, unit) } ?: "--", Modifier.weight(1f))
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(130.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.Bottom
        ) {
            val chartValues = values.ifEmpty { listOf(0.0) }
            chartValues.forEach { value ->
                val ratio = ((value - minValue) / spread).coerceIn(0.0, 1.0)
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height((18 + ratio * 112).dp)
                        .clip(RoundedCornerShape(topStart = 10.dp, topEnd = 10.dp, bottomStart = 4.dp, bottomEnd = 4.dp))
                        .background(if (values.isEmpty()) MaterialTheme.colorScheme.outline.copy(alpha = 0.20f) else DeltsAccent)
                )
            }
        }
    }
}

@Composable
private fun MetricStatTile(title: String, value: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.28f))
            .height(48.dp)
            .padding(horizontal = 10.dp),
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Text(
            text = value,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.ExtraBold,
            color = MaterialTheme.colorScheme.onBackground,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

private fun averageMetricChange(points: List<Pair<Long, Double>>, range: ProgressRange): Double? {
    val first = points.firstOrNull() ?: return null
    val last = points.lastOrNull() ?: return null
    if (first.first == last.first) return null
    val elapsedMs = (last.first - first.first).coerceAtLeast(1L).toDouble()
    val periodMs = range.averagePeriodMs?.toDouble() ?: elapsedMs
    return (last.second - first.second) / elapsedMs * periodMs
}

private fun formatMetricValue(value: Double, unit: String): String =
    if (unit == "%") String.format(Locale.US, "%.1f%%", value) else String.format(Locale.US, "%.1f %s", value, unit)

private fun formatSignedMetricValue(value: Double, unit: String): String {
    val sign = if (value > 0.0) "+" else ""
    return sign + formatMetricValue(value, unit)
}

@Composable
private fun WorkoutHistoryCard(workout: WorkoutHistoryRecord) {
    val completedSets = workout.exercises.sumOf { exercise -> exercise.sets.count { it.completed } }
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.24f))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(9.dp)
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Text(
                text = workout.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.weight(1f),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "${workout.durationMinutes}m",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.ExtraBold,
                color = DeltsAccent
            )
        }
        Text(
            text = "${completedSets} ${if (completedSets == 1) "set" else "sets"} - ${workout.bodyPart}",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        val stamps = workout.exercises.flatMap { it.sets }.mapNotNull { it.elapsedSeconds }.take(4)
        if (stamps.isNotEmpty()) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                stamps.forEach { seconds ->
                    Text(
                        text = elapsedDisplay(seconds),
                        style = MaterialTheme.typography.labelSmall,
                        color = DeltsSecondaryAccent,
                        modifier = Modifier
                            .clip(RoundedCornerShape(13.dp))
                            .background(DeltsSecondaryAccent.copy(alpha = 0.10f))
                            .padding(horizontal = 8.dp, vertical = 5.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun ProfileScreen(
    profile: AndroidProfile,
    updateProfile: (AndroidProfile) -> Unit,
    exerciseLibrary: List<ExerciseItem>,
    measurementSystem: MeasurementSystem,
    updateMeasurementSystem: (MeasurementSystem) -> Unit,
    aiSettings: AISettings,
    updateAISettings: (AISettings) -> Unit,
    keyStore: GeminiKeyStore,
    fallbackKeyStore: GeminiKeyStore,
    padding: PaddingValues
) {
    var apiKey by remember { mutableStateOf(keyStore.load()) }
    var hasSavedKey by remember { mutableStateOf(keyStore.hasKey()) }
    var fallbackApiKey by remember { mutableStateOf(fallbackKeyStore.load()) }
    var hasSavedFallbackKey by remember { mutableStateOf(fallbackKeyStore.hasKey()) }
    val focusManager = LocalFocusManager.current
    val datasetLevels = remember(exerciseLibrary) { exerciseLibrary.map { it.level }.distinctSortedLevels() }
    val selectedDatasetLevel = remember(profile.experience, datasetLevels) {
        when {
            datasetLevels.contains(profile.experience) -> profile.experience
            profile.experience == "Advanced" && datasetLevels.contains("Expert") -> "Expert"
            else -> datasetLevels.firstOrNull().orEmpty()
        }
    }
    val datasetPrimaryMuscles = remember(exerciseLibrary) { exerciseLibrary.flatMap { it.primaryMuscles }.distinctSorted() }
    val datasetRawEquipment = remember(exerciseLibrary) { exerciseLibrary.map { it.rawEquipment }.distinctSorted() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .clearFocusOnTap(focusManager)
            .padding(padding)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 12.dp, bottom = 112.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        ProfileSection(
            title = "About",
            subtitle = "Basic details used to shape plans.",
            icon = Icons.Filled.Person
        ) {
            CompactTextFieldRow(
                title = "Name",
                icon = Icons.Filled.Person,
                value = profile.name,
                onValueChange = { updateProfile(profile.copy(name = it)) }
            )
            ProfileRowDivider()
            CompactDropdownRow(
                title = "Gender",
                icon = Icons.Filled.Person,
                value = profile.gender,
                options = genderOptions,
                selectedOption = profile.gender
            ) { selected ->
                updateProfile(profile.copy(gender = selected))
            }
            ProfileRowDivider()
            CompactAgeRow(age = profile.age) {
                updateProfile(profile.copy(age = it))
            }
            ProfileRowDivider()
            CompactDropdownRow(
                title = "Units",
                icon = Icons.Filled.Build,
                value = measurementSystem.title,
                options = MeasurementSystem.values().map { it.title },
                selectedOption = measurementSystem.title
            ) { selected ->
                MeasurementSystem.values().firstOrNull { it.title == selected }?.let(updateMeasurementSystem)
            }
            ProfileRowDivider()
            HeightMeasurementCompactRow(
                measurementSystem = measurementSystem,
                centimeters = profile.heightCm
            ) { updateProfile(profile.copy(heightCm = it)) }
            ProfileRowDivider()
            WeightMeasurementCompactRow(
                measurementSystem = measurementSystem,
                kilograms = profile.weightKg
            ) { updateProfile(profile.copy(weightKg = it)) }
            ProfileRowDivider()
            WeightMeasurementCompactRow(
                title = "Goal weight",
                icon = Icons.Filled.Flag,
                measurementSystem = measurementSystem,
                kilograms = profile.goalWeightKg
            ) { updateProfile(profile.copy(goalWeightKg = it)) }
            ProfileRowDivider()
            PercentMeasurementCompactRow(
                title = "Current body fat",
                icon = Icons.Filled.Favorite,
                value = profile.currentBodyFat,
                range = 3..60
            ) { updateProfile(profile.copy(currentBodyFat = it)) }
            ProfileRowDivider()
            PercentMeasurementCompactRow(
                title = "Desired body fat",
                icon = Icons.Filled.Flag,
                value = profile.desiredBodyFat,
                range = 3..45
            ) { updateProfile(profile.copy(desiredBodyFat = it)) }
        }

        ProfileSection(
            title = "Goals & Constraints",
            subtitle = "Training targets, focus, and limits before plans are generated.",
            icon = Icons.Filled.Flag
        ) {
            CompactDropdownRow(
                title = "Level",
                icon = Icons.Filled.FlashOn,
                value = selectedDatasetLevel.ifBlank { "Unspecified" },
                options = datasetLevels.ifEmpty { listOf("Unspecified") },
                selectedOption = selectedDatasetLevel.ifBlank { "Unspecified" }
            ) { selected ->
                if (datasetLevels.contains(selected)) {
                    updateProfile(profile.copy(experience = selected))
                }
            }
            ProfileRowDivider()
            CompactMultiSelectRow(
                title = "Goals",
                icon = Icons.Filled.Flag,
                items = profileGoalOptions,
                selected = profile.selectedGoals.ifEmpty { setOf(profile.mainGoal) },
            ) { item ->
                val nextGoals = toggleInSet(profile.selectedGoals.ifEmpty { setOf(profile.mainGoal) }, item)
                    .ifEmpty { setOf(profile.mainGoal) }
                val primaryGoal = profileGoalOptions.firstOrNull {
                    it != otherGoalOption && nextGoals.contains(it)
                } ?: profile.mainGoal
                updateProfile(profile.copy(mainGoal = primaryGoal, selectedGoals = nextGoals))
            }
            if (profile.selectedGoals.contains(otherGoalOption)) {
                ProfileRowDivider()
                CompactTextFieldRow(
                    title = "Extra goals",
                    icon = Icons.Filled.List,
                    value = profile.extraGoals,
                    placeholder = "Optional",
                    onValueChange = { updateProfile(profile.copy(extraGoals = it)) }
                )
            }
            ProfileRowDivider()
            TargetMuscleSelectorRow(
                selected = profile.bodyFocus,
                allowedValues = datasetPrimaryMuscles,
                gender = profile.gender,
                onSelectionChange = { nextSelection ->
                    updateProfile(profile.copy(bodyFocus = nextSelection))
                }
            )
            ProfileRowDivider()
            CompactMultiSelectRow(
                title = "Issues",
                icon = Icons.Filled.Warning,
                items = issueOptions.map { it.title },
                selected = profile.issues,
            ) { item ->
                updateProfile(profile.copy(issues = toggleInSet(profile.issues, item)))
            }
            if (profile.issues.contains(otherIssueOption)) {
                ProfileRowDivider()
                CompactTextFieldRow(
                    title = "Extra issues",
                    icon = Icons.Filled.List,
                    value = profile.extraIssues,
                    placeholder = "Optional",
                    onValueChange = { updateProfile(profile.copy(extraIssues = it)) }
                )
            }
        }

        ProfileSection(
            title = "AI Settings",
            subtitle = "Provider, model, local key, and fallback.",
            icon = Icons.Filled.VpnKey,
            badge = if (hasSavedKey) "Ready" else null
        ) {
            CompactDropdownRow(
                title = "Provider",
                icon = Icons.Filled.Build,
                value = aiSettings.provider,
                options = aiProviderOptions,
                selectedOption = aiSettings.provider
            ) { selected ->
                updateAISettings(aiSettings.withProvider(selected))
            }
            if (aiSettings.provider == customAIProvider) {
                ProfileRowDivider()
                CompactTextFieldRow(
                    title = "Provider name",
                    icon = Icons.Filled.List,
                    value = aiSettings.customProvider,
                    placeholder = "Custom provider",
                    onValueChange = { updateAISettings(aiSettings.copy(customProvider = it)) }
                )
            }
            ProfileRowDivider()
            CompactDropdownRow(
                title = "Model",
                icon = Icons.Filled.List,
                value = aiSettings.model,
                options = modelOptionsForProvider(aiSettings.provider),
                selectedOption = aiSettings.model
            ) { selected ->
                updateAISettings(aiSettings.copy(model = selected))
            }
            if (aiSettings.model == customAIModel) {
                ProfileRowDivider()
                CompactTextFieldRow(
                    title = "Model name",
                    icon = Icons.Filled.List,
                    value = aiSettings.customModel,
                    placeholder = "Custom model",
                    onValueChange = { updateAISettings(aiSettings.copy(customModel = it)) }
                )
            }
            ProfileRowDivider()
            CompactAPIKeyRow(
                title = "API key",
                apiKey = apiKey,
                hasSavedKey = hasSavedKey,
                onApiKeyChange = { apiKey = it },
                save = {
                    keyStore.save(apiKey)
                    apiKey = keyStore.load()
                    hasSavedKey = keyStore.hasKey()
                },
                clear = {
                    keyStore.clear()
                    apiKey = ""
                    hasSavedKey = false
                }
            )
            ProfileRowDivider()
            CompactToggleRow(
                title = "Fallback",
                icon = Icons.Filled.History,
                checked = aiSettings.fallbackEnabled,
                onCheckedChange = { updateAISettings(aiSettings.copy(fallbackEnabled = it)) }
            )
            if (aiSettings.fallbackEnabled) {
                ProfileRowDivider()
                CompactDropdownRow(
                    title = "Fallback provider",
                    icon = Icons.Filled.Build,
                    value = aiSettings.fallbackProvider,
                    options = aiProviderOptions,
                    selectedOption = aiSettings.fallbackProvider
                ) { selected ->
                    updateAISettings(aiSettings.withFallbackProvider(selected))
                }
                if (aiSettings.fallbackProvider == customAIProvider) {
                    ProfileRowDivider()
                    CompactTextFieldRow(
                        title = "Fallback name",
                        icon = Icons.Filled.List,
                        value = aiSettings.fallbackCustomProvider,
                        placeholder = "Custom provider",
                        onValueChange = { updateAISettings(aiSettings.copy(fallbackCustomProvider = it)) }
                    )
                }
                ProfileRowDivider()
                CompactDropdownRow(
                    title = "Fallback model",
                    icon = Icons.Filled.List,
                    value = aiSettings.fallbackModel,
                    options = modelOptionsForProvider(aiSettings.fallbackProvider),
                    selectedOption = aiSettings.fallbackModel
                ) { selected ->
                    updateAISettings(aiSettings.copy(fallbackModel = selected))
                }
                if (aiSettings.fallbackModel == customAIModel) {
                    ProfileRowDivider()
                    CompactTextFieldRow(
                        title = "Fallback model name",
                        icon = Icons.Filled.List,
                        value = aiSettings.fallbackCustomModel,
                        placeholder = "Custom model",
                        onValueChange = { updateAISettings(aiSettings.copy(fallbackCustomModel = it)) }
                    )
                }
                ProfileRowDivider()
                CompactAPIKeyRow(
                    title = "Fallback key",
                    apiKey = fallbackApiKey,
                    hasSavedKey = hasSavedFallbackKey,
                    onApiKeyChange = { fallbackApiKey = it },
                    save = {
                        fallbackKeyStore.save(fallbackApiKey)
                        fallbackApiKey = fallbackKeyStore.load()
                        hasSavedFallbackKey = fallbackKeyStore.hasKey()
                    },
                    clear = {
                        fallbackKeyStore.clear()
                        fallbackApiKey = ""
                        hasSavedFallbackKey = false
                    }
                )
            }
        }

        ProfileSection(
            title = "Workout Setup",
            subtitle = "Tune how training fits into the week.",
            icon = Icons.Filled.CalendarToday
        ) {
            CompactDropdownRow(
                title = "Frequency",
                icon = Icons.Filled.CalendarToday,
                value = "${profile.frequency.coerceIn(1, 7)} days/week",
                options = frequencyOptions,
                selectedOption = "${profile.frequency.coerceIn(1, 7)} days/week"
            ) { selected ->
                selected.substringBefore(" ").toIntOrNull()?.let {
                    updateProfile(profile.copy(frequency = it.coerceIn(1, 7)))
                }
            }
            ProfileRowDivider()
            CompactDropdownRow(
                title = "Workout split",
                icon = Icons.Filled.Build,
                value = profile.workoutSplit,
                options = workoutSplitOptions,
                selectedOption = profile.workoutSplit
            ) { selected ->
                updateProfile(profile.copy(workoutSplit = selected))
            }
            if (profile.workoutSplit == "Custom") {
                ProfileRowDivider()
                CompactTextFieldRow(
                    title = "Custom split",
                    icon = Icons.Filled.List,
                    value = profile.customWorkoutSplit,
                    placeholder = "Write split",
                    onValueChange = { updateProfile(profile.copy(customWorkoutSplit = it)) }
                )
            }
            ProfileRowDivider()
            CompactDurationRow(duration = profile.duration) {
                updateProfile(profile.copy(duration = it))
            }
            ProfileRowDivider()
            CompactMultiSelectRow(
                title = "Equipment",
                icon = Icons.Filled.FitnessCenter,
                items = datasetRawEquipment,
                selected = profile.availableEquipment,
            ) { item ->
                updateProfile(profile.copy(availableEquipment = toggleInSet(profile.availableEquipment, item)))
            }
        }

    }
}

@Composable
private fun DatasetStartHero(
    item: ExerciseItem?,
    imagePaths: List<String>,
    fallbackIcon: ImageVector
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(248.dp)
            .clip(RoundedCornerShape(34.dp))
            .background(
                Brush.verticalGradient(
                    listOf(
                        MaterialTheme.colorScheme.surfaceVariant,
                        Color(0xFF263021),
                        Color.Black
                    )
                )
            )
    ) {
        ExerciseVisual(
            imagePaths = imagePaths,
            fallbackIcon = fallbackIcon,
            modifier = Modifier.matchParentSize(),
            cornerRadius = 34,
            iconSize = 108,
            contentScale = ContentScale.Crop
        )

        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.30f),
                            Color.Black.copy(alpha = 0.88f)
                        )
                    )
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            DeltsGlassLabel(title = "FreeExerciseDB", icon = Icons.Filled.List)

            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = item?.name ?: "Exercise Library",
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = item?.let { "${it.primaryMusclesTitle()} - ${it.rawEquipment} - ${it.level}" } ?: "Dataset fields only",
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.White.copy(alpha = 0.76f),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                if (item != null) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(24.dp))
                            .background(Color.Black.copy(alpha = 0.36f))
                            .padding(horizontal = 12.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        HeroMetric("Primary", item.primaryMusclesTitle(), Icons.Filled.FitnessCenter, Modifier.weight(1f))
                        HeroMetric("Level", item.level, Icons.Filled.FlashOn, Modifier.weight(1f))
                        HeroMetric("Gear", item.rawEquipment, Icons.Filled.FitnessCenter, Modifier.weight(1f))
                        HeroMetric("Category", item.category, Icons.Filled.List, Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

@Composable
private fun HeroMetric(title: String, value: String, icon: ImageVector, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(icon, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(16.dp))
        Text(
            text = value,
            style = MaterialTheme.typography.labelLarge,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Text(
            text = title,
            style = MaterialTheme.typography.labelSmall,
            color = Color.White.copy(alpha = 0.58f),
            maxLines = 1
        )
    }
}

@Composable
private fun ExerciseVisual(
    imagePaths: List<String>,
    fallbackIcon: ImageVector,
    modifier: Modifier = Modifier,
    cornerRadius: Int = 18,
    iconSize: Int = 42,
    contentScale: ContentScale = ContentScale.Crop
) {
    val context = LocalContext.current
    val frames = remember(imagePaths, context) {
        imagePaths
            .take(2)
            .mapNotNull { imagePath ->
                runCatching {
                    context.assets.open("images/$imagePath").use { stream ->
                        BitmapFactory.decodeStream(stream)?.asImageBitmap()
                    }
                }.getOrNull()
            }
    }
    var frameIndex by remember(imagePaths) { mutableStateOf(0) }

    LaunchedEffect(frames.size, imagePaths) {
        frameIndex = 0
        if (frames.size > 1) {
            while (true) {
                delay(850)
                frameIndex = (frameIndex + 1) % frames.size
            }
        }
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(cornerRadius.dp))
            .background(
                Brush.linearGradient(
                    listOf(
                        MaterialTheme.colorScheme.surfaceVariant,
                        MaterialTheme.colorScheme.surface,
                        DeltsSecondaryAccent.copy(alpha = 0.28f)
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        if (frames.isNotEmpty()) {
            Image(
                bitmap = frames[frameIndex.coerceAtMost(frames.lastIndex)],
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = contentScale
            )
        } else {
            Icon(
                imageVector = fallbackIcon,
                contentDescription = null,
                modifier = Modifier.size(iconSize.dp),
                tint = DeltsAccent.copy(alpha = 0.72f)
            )
        }
    }
}

@Composable
private fun StartSection(index: String? = null, title: String, subtitle: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
            if (index != null) {
                Text(
                    text = index,
                    style = MaterialTheme.typography.labelLarge,
                    color = DeltsAccent
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(14.dp), content = content)
    }
}

@Composable
private fun DeltsPillButton(
    title: String,
    icon: ImageVector,
    selected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = modifier.height(42.dp),
        shape = RoundedCornerShape(21.dp),
        contentPadding = PaddingValues(horizontal = 13.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (selected) DeltsAccent else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.52f),
            contentColor = if (selected) DeltsOnAccent else MaterialTheme.colorScheme.onBackground
        ),
        elevation = ButtonDefaults.buttonElevation(defaultElevation = 0.dp, pressedElevation = 0.dp)
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(16.dp))
        Spacer(modifier = Modifier.width(7.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun HorizontalChipRail(content: @Composable RowScope.() -> Unit) {
    Row(
        modifier = Modifier
            .horizontalScroll(rememberScrollState())
            .padding(vertical = 1.dp),
        horizontalArrangement = Arrangement.spacedBy(9.dp),
        content = content
    )
}

private fun Modifier.clearFocusOnTap(focusManager: FocusManager): Modifier =
    pointerInput(focusManager) {
        awaitEachGesture {
            awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
            focusManager.clearFocus()
        }
    }

@Composable
private fun LibrarySearchPill(
    search: String,
    onSearchChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .height(46.dp),
        shape = RoundedCornerShape(17.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = if (search.isBlank()) 0.52f else 0.66f),
        border = BorderStroke(
            1.dp,
            if (search.isBlank()) {
                MaterialTheme.colorScheme.outline.copy(alpha = 0.24f)
            } else {
                DeltsAccent.copy(alpha = 0.40f)
            }
        )
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Search,
                contentDescription = null,
                tint = if (search.isBlank()) DeltsSecondaryAccent else DeltsAccent,
                modifier = Modifier.size(15.dp)
            )
            Box(modifier = Modifier.weight(1f)) {
                if (search.isBlank()) {
                    Text(
                        text = "Search",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1
                    )
                }
                BasicTextField(
                    value = search,
                    onValueChange = onSearchChange,
                    singleLine = true,
                    textStyle = MaterialTheme.typography.labelLarge.copy(
                        color = MaterialTheme.colorScheme.onBackground
                    ),
                    modifier = Modifier.fillMaxWidth()
                )
            }
            if (search.isNotBlank()) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = "Clear search",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier
                        .size(16.dp)
                        .clickable { onSearchChange("") }
                )
            }
        }
    }
}

@Composable
private fun LibraryFilterMenu(
    title: String,
    value: String,
    icon: ImageVector,
    active: Boolean,
    options: List<String>,
    selectedOption: String?,
    allTitle: String,
    onSelect: (String?) -> Unit
) {
    var expanded by rememberSaveable { mutableStateOf(false) }

    Box {
        Button(
            onClick = { expanded = true },
            modifier = Modifier.height(46.dp),
            shape = RoundedCornerShape(17.dp),
            contentPadding = PaddingValues(horizontal = 12.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = if (active) DeltsAccent else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.52f),
                contentColor = if (active) DeltsOnAccent else MaterialTheme.colorScheme.onBackground
            ),
            elevation = ButtonDefaults.buttonElevation(defaultElevation = 0.dp, pressedElevation = 0.dp)
        ) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(15.dp))
            Spacer(modifier = Modifier.width(7.dp))
            Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.labelSmall,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = value,
                    style = MaterialTheme.typography.labelLarge,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier.heightIn(max = 360.dp)
        ) {
            DropdownMenuItem(
                text = { Text(allTitle, style = MaterialTheme.typography.bodyLarge) },
                leadingIcon = if (selectedOption == null) {
                    {
                        Icon(Icons.Filled.Check, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(18.dp))
                    }
                } else {
                    null
                },
                onClick = {
                    onSelect(null)
                    expanded = false
                }
            )

            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(option, style = MaterialTheme.typography.bodyLarge) },
                    leadingIcon = if (selectedOption == option) {
                        {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(18.dp))
                        }
                    } else {
                        null
                    },
                    onClick = {
                        onSelect(option)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
private fun ExercisePlanRow(exercise: ExercisePlan) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ExerciseVisual(
            imagePaths = exercise.imagePaths,
            fallbackIcon = Icons.Filled.FitnessCenter,
            modifier = Modifier.size(82.dp),
            cornerRadius = 18,
            iconSize = 34
        )
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Text(
                text = exercise.name,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "${exercise.primaryMuscles.ifEmpty { listOf("Unspecified") }.joinToString(", ")} - ${exercise.rawEquipment} - ${exercise.level}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = exercise.category,
                style = MaterialTheme.typography.labelLarge,
                color = DeltsSecondaryAccent,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun ResultsHeader(title: String, subtitle: String, onReset: (() -> Unit)? = null) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(text = title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
            Text(text = subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        if (onReset != null) {
            DeltsPillButton(
                title = "Reset",
                icon = Icons.Filled.Close,
                selected = false,
                onClick = onReset
            )
        }
    }
}

@Composable
private fun ExerciseLibraryRow(item: ExerciseItem, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            ExerciseVisual(
                imagePaths = item.imagePaths,
                fallbackIcon = Icons.Filled.FitnessCenter,
                modifier = Modifier.size(104.dp),
                cornerRadius = 18,
                iconSize = 42
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                Text(
                    text = item.name,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "${item.primaryMusclesTitle()} - ${item.rawEquipment} - ${item.level}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = item.databaseSummary(),
                    style = MaterialTheme.typography.labelLarge,
                    color = DeltsSecondaryAccent,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Icon(
                Icons.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.outline
            )
        }
    }
    HorizontalDivider(color = DividerDefaults.color.copy(alpha = 0.32f))
}

@Composable
private fun ExerciseLibraryDetailScreen(
    item: ExerciseItem,
    padding: PaddingValues,
    onBack: () -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding),
        contentPadding = PaddingValues(bottom = 112.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        item {
            ExerciseDetailHeader(
                title = item.name,
                onBack = onBack,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 14.dp)
            )
        }

        item {
            ExerciseDetailHero(item = item)
        }

        item {
            ExerciseDetailMetricGrid(
                item = item,
                modifier = Modifier.padding(horizontal = 20.dp)
            )
        }

        item {
            HorizontalDivider(
                color = DividerDefaults.color.copy(alpha = 0.34f),
                modifier = Modifier.padding(horizontal = 20.dp)
            )
        }

        item {
            ExerciseDetailInstructions(
                instructions = item.instructions,
                modifier = Modifier.padding(horizontal = 20.dp)
            )
        }
    }
}

@Composable
private fun ExerciseDetailHeader(
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxWidth(),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .size(56.dp)
                .clip(CircleShape)
                .clickable(onClick = onBack)
                .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.64f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Filled.ArrowBack,
                contentDescription = "Back",
                tint = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.size(30.dp)
            )
        }

        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.ExtraBold,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = 72.dp)
        )
    }
}

@Composable
private fun ExerciseDetailHero(item: ExerciseItem) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(294.dp)
    ) {
        ExerciseVisual(
            imagePaths = item.imagePaths,
            fallbackIcon = Icons.Filled.FitnessCenter,
            modifier = Modifier.matchParentSize(),
            cornerRadius = 0,
            iconSize = 112,
            contentScale = ContentScale.Crop
        )
    }
}

@Composable
private fun ExerciseDetailMetricGrid(
    item: ExerciseItem,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
            ExerciseDetailMetric(
                title = "Level",
                value = item.level,
                icon = Icons.Filled.FlashOn,
                modifier = Modifier.weight(1f)
            )
            ExerciseDetailMetric(
                title = "Category",
                value = item.category,
                icon = Icons.Filled.List,
                modifier = Modifier.weight(1f)
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
            ExerciseDetailMetric(
                title = "Force",
                value = item.force,
                icon = Icons.Filled.Flag,
                modifier = Modifier.weight(1f)
            )
            ExerciseDetailMetric(
                title = "Mechanic",
                value = item.mechanic,
                icon = Icons.Filled.Build,
                modifier = Modifier.weight(1f)
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
            ExerciseDetailMetric(
                title = "Primary",
                value = item.primaryMusclesTitle(),
                icon = Icons.Filled.FitnessCenter,
                modifier = Modifier.weight(1f)
            )
            ExerciseDetailMetric(
                title = "Secondary",
                value = item.secondaryMusclesTitle(),
                icon = Icons.Filled.FitnessCenter,
                modifier = Modifier.weight(1f)
            )
            ExerciseDetailMetric(
                title = "Equipment",
                value = item.rawEquipment,
                icon = Icons.Filled.FitnessCenter,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun ExerciseDetailMetric(
    title: String,
    value: String,
    icon: ImageVector,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .heightIn(min = 64.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.22f))
            .padding(horizontal = 8.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(
                icon,
                contentDescription = null,
                tint = DeltsAccent,
                modifier = Modifier.size(14.dp)
            )
            Text(
                text = title,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        Text(
            text = value,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
    }
}

@Composable
private fun ExerciseDetailInstructions(
    instructions: List<String>,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Filled.List,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.size(28.dp)
            )
            Text(
                text = "Instructions",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground
            )
        }

        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            instructions.forEachIndexed { index, instruction ->
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.Top) {
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .background(DeltsAccent),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "${index + 1}",
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Bold,
                            color = DeltsOnAccent
                        )
                    }
                    Text(
                        text = instruction,
                        modifier = Modifier.weight(1f),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun ProfileSection(
    title: String,
    subtitle: String,
    icon: ImageVector,
    badge: String? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.ExtraBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.weight(1f)
            )
            if (badge != null) {
                Text(
                    text = badge,
                    style = MaterialTheme.typography.labelLarge,
                    color = DeltsAccent,
                    modifier = Modifier
                        .clip(RoundedCornerShape(14.dp))
                        .background(DeltsAccent.copy(alpha = 0.10f))
                        .padding(horizontal = 9.dp, vertical = 4.dp)
                )
            }
        }
        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(28.dp),
            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.24f),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.22f))
        ) {
            Column(
                modifier = Modifier.padding(horizontal = 14.dp),
                verticalArrangement = Arrangement.spacedBy(0.dp),
                content = content
            )
        }
    }
}

@Composable
private fun ProfileSettingRow(
    title: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 58.dp)
            .padding(vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Icon(icon, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(24.dp))
        Text(
            text = title,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onBackground,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        content()
    }
}

@Composable
private fun ProfileRowDivider() {
    HorizontalDivider(
        modifier = Modifier.padding(start = 52.dp),
        color = DividerDefaults.color.copy(alpha = 0.30f)
    )
}

@Composable
private fun CompactTextFieldRow(
    title: String,
    icon: ImageVector,
    value: String,
    placeholder: String = title,
    onValueChange: (String) -> Unit
) {
    ProfileSettingRow(title = title, icon = icon) {
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.width(178.dp),
            singleLine = true,
            textStyle = MaterialTheme.typography.titleMedium.copy(
                color = MaterialTheme.colorScheme.onBackground,
                textAlign = TextAlign.End,
                fontWeight = FontWeight.SemiBold
            ),
            decorationBox = { innerTextField ->
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
                    if (value.isBlank()) {
                        Text(
                            text = placeholder,
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                    innerTextField()
                }
            }
        )
    }
}

@Composable
private fun CompactDropdownRow(
    title: String,
    icon: ImageVector,
    value: String,
    options: List<String>,
    selectedOption: String,
    onSelect: (String) -> Unit
) {
    var expanded by rememberSaveable { mutableStateOf(false) }

    Box {
        ProfileSettingRow(
            title = title,
            icon = icon,
            modifier = Modifier.clickable { expanded = true }
        ) {
            CompactValueLabel(value = value)
        }

        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(option, style = MaterialTheme.typography.bodyLarge) },
                    leadingIcon = if (option == selectedOption) {
                        {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(18.dp))
                        }
                    } else {
                        null
                    },
                    onClick = {
                        onSelect(option)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
private fun TargetMuscleSelectorRow(
    selected: Set<String>,
    allowedValues: List<String>,
    gender: String,
    onSelectionChange: (Set<String>) -> Unit
) {
    var showDialog by rememberSaveable { mutableStateOf(false) }
    val normalizedSelection = remember(selected, allowedValues) {
        normalizeTargetMuscleSelection(selected, allowedValues)
    }
    val selectedGroups = remember(normalizedSelection, allowedValues) {
        selectedTargetMuscleGroups(normalizedSelection, allowedValues)
    }
    val summary = remember(normalizedSelection, allowedValues) {
        targetMuscleSummary(normalizedSelection, allowedValues)
    }

    Column(modifier = Modifier.fillMaxWidth()) {
        ProfileSettingRow(
            title = "Target muscles",
            icon = Icons.Filled.FitnessCenter,
            modifier = Modifier.clickable { showDialog = true }
        ) {
            CompactValueLabel(value = summary)
        }

        if (selectedGroups.isNotEmpty()) {
            Row(
                modifier = Modifier
                    .padding(start = 52.dp, end = 8.dp, bottom = 10.dp)
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                selectedGroups.forEach { group ->
                    TargetMuscleChip(title = group.title)
                }
            }
        }
    }

    if (showDialog) {
        TargetMuscleSelectionDialog(
            selected = normalizedSelection,
            allowedValues = allowedValues,
            gender = gender,
            onSelectionChange = onSelectionChange,
            onDismiss = { showDialog = false }
        )
    }
}

@Composable
private fun TargetMuscleSelectionDialog(
    selected: Set<String>,
    allowedValues: List<String>,
    gender: String,
    onSelectionChange: (Set<String>) -> Unit,
    onDismiss: () -> Unit
) {
    val groups = remember(allowedValues) { targetMuscleGroupsFor(allowedValues) }
    val selectedGroups = remember(selected, allowedValues) {
        selectedTargetMuscleGroups(selected, allowedValues)
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "Target muscles",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.ExtraBold
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text(
                    text = "Swipe grouped body areas. Choices save the real dataset muscles shown on each card.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    contentPadding = PaddingValues(horizontal = 2.dp)
                ) {
                    items(groups) { group ->
                        val groupMuscles = group.muscles.filter { allowedValues.contains(it) }.toSet()
                        TargetMuscleCard(
                            group = group,
                            gender = gender,
                            isSelected = selected.containsAll(groupMuscles),
                            onToggle = {
                                onSelectionChange(toggleTargetMuscleGroup(selected, group, allowedValues))
                            }
                        )
                    }
                }

                if (selectedGroups.isNotEmpty()) {
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        selectedGroups.forEach { group ->
                            TargetMuscleChip(title = group.title)
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Done", fontWeight = FontWeight.Bold)
            }
        }
    )
}

@Composable
private fun TargetMuscleCard(
    group: TargetMuscleGroup,
    gender: String,
    isSelected: Boolean,
    onToggle: () -> Unit
) {
    Card(
        modifier = Modifier
            .width(264.dp)
            .height(320.dp)
            .clickable(onClick = onToggle),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = if (isSelected) 0.40f else 0.24f)
        ),
        border = BorderStroke(
            width = if (isSelected) 1.2.dp else 0.6.dp,
            color = if (isSelected) DeltsAccent.copy(alpha = 0.62f) else MaterialTheme.colorScheme.outline.copy(alpha = 0.22f)
        )
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(126.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.44f))
            ) {
                TargetMuscleAssetImage(
                    imageRes = group.imageRes(gender),
                    modifier = Modifier.matchParentSize()
                )

                if (isSelected) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(10.dp)
                            .size(30.dp)
                            .clip(CircleShape)
                            .background(DeltsAccent),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Filled.Check,
                            contentDescription = null,
                            tint = DeltsOnAccent,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            }

            Text(
                text = group.title,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.ExtraBold,
                color = MaterialTheme.colorScheme.onBackground,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            Text(
                text = group.detail,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Row(
                modifier = Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(7.dp)
            ) {
                group.muscles.forEach { muscle ->
                    TargetMuscleChip(title = muscle)
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            Button(
                onClick = onToggle,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isSelected) MaterialTheme.colorScheme.surfaceVariant else DeltsAccent,
                    contentColor = if (isSelected) MaterialTheme.colorScheme.onBackground else DeltsOnAccent
                )
            ) {
                Text(if (isSelected) "Remove" else "Select", fontWeight = FontWeight.ExtraBold)
            }
        }
    }
}

@Composable
private fun TargetMuscleAssetImage(
    @DrawableRes imageRes: Int,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.background(MaterialTheme.colorScheme.surface.copy(alpha = 0.52f))) {
        Image(
            painter = painterResource(id = imageRes),
            contentDescription = null,
            modifier = Modifier.matchParentSize(),
            contentScale = ContentScale.Crop
        )
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.34f))
                    )
                )
        )
    }
}

@Composable
private fun TargetMuscleChip(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelLarge,
        fontWeight = FontWeight.Bold,
        color = DeltsAccent,
        maxLines = 1,
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(DeltsAccent.copy(alpha = 0.12f))
            .padding(horizontal = 9.dp, vertical = 6.dp)
    )
}

@Composable
private fun CompactMultiSelectRow(
    title: String,
    icon: ImageVector,
    items: List<String>,
    selected: Set<String>,
    onToggle: (String) -> Unit
) {
    var expanded by rememberSaveable { mutableStateOf(false) }
    val selectedItems = items.filter { selected.contains(it) }
    val summary = when {
        selectedItems.isEmpty() -> "None"
        selectedItems.size <= 2 -> selectedItems.joinToString(", ")
        else -> "${selectedItems.size} selected"
    }

    Box {
        ProfileSettingRow(
            title = title,
            icon = icon,
            modifier = Modifier.clickable { expanded = true }
        ) {
            CompactValueLabel(value = summary)
        }

        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            items.forEach { item ->
                DropdownMenuItem(
                    text = { Text(item, style = MaterialTheme.typography.bodyLarge) },
                    leadingIcon = if (selected.contains(item)) {
                        {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(18.dp))
                        }
                    } else {
                        null
                    },
                    onClick = {
                        onToggle(item)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
private fun CompactValueLabel(value: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(7.dp)) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.End,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.widthIn(max = 178.dp)
        )
        Icon(
            Icons.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(22.dp)
        )
    }
}

@Composable
private fun CompactAPIKeyRow(
    title: String,
    apiKey: String,
    hasSavedKey: Boolean,
    onApiKeyChange: (String) -> Unit,
    save: () -> Unit,
    clear: () -> Unit
) {
    ProfileSettingRow(
        title = title,
        icon = if (hasSavedKey) Icons.Filled.Check else Icons.Filled.VpnKey
    ) {
        BasicTextField(
            value = apiKey,
            onValueChange = onApiKeyChange,
            modifier = Modifier.width(92.dp),
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            textStyle = MaterialTheme.typography.titleMedium.copy(
                color = MaterialTheme.colorScheme.onBackground,
                textAlign = TextAlign.End,
                fontWeight = FontWeight.SemiBold
            ),
            decorationBox = { innerTextField ->
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
                    if (apiKey.isBlank()) {
                        Text(
                            text = if (hasSavedKey) "Saved" else "Paste key",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                    innerTextField()
                }
            }
        )
        CompactIconButton(icon = Icons.Filled.Check, onClick = save)
        CompactIconButton(icon = Icons.Filled.Close, onClick = clear)
    }
}

@Composable
private fun CompactToggleRow(
    title: String,
    icon: ImageVector,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    ProfileSettingRow(title = title, icon = icon) {
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

@Composable
private fun CompactIconButton(icon: ImageVector, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(32.dp)
            .clip(CircleShape)
            .clickable(onClick = onClick)
            .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.58f)),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onBackground, modifier = Modifier.size(17.dp))
    }
}

@Composable
private fun CompactNumberStepperRow(
    title: String,
    icon: ImageVector,
    value: Int,
    range: IntRange,
    suffix: String,
    onChange: (Int) -> Unit
) {
    ProfileSettingRow(title = title, icon = icon) {
        Text(
            text = "$value $suffix",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground,
            maxLines = 1
        )
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            CompactIconButton(Icons.Filled.Close) { onChange((value - 1).coerceIn(range)) }
            CompactIconButton(Icons.Filled.Add) { onChange((value + 1).coerceIn(range)) }
        }
    }
}

@Composable
private fun CompactAgeRow(
    age: Int,
    onChange: (Int) -> Unit
) {
    val ageRange = 0..120
    val selectedAge = age.coerceIn(ageRange)

    CompactMeasurementRow(
        title = "Age",
        icon = Icons.Filled.CalendarToday,
        valueText = "$selectedAge yr"
    ) {
        ScrollingNumberSelector("yr", selectedAge, ageRange, Modifier.fillMaxWidth()) {
            onChange(it)
        }
    }
}

@Composable
private fun CompactDurationRow(
    duration: Int,
    onChange: (Int) -> Unit
) {
    val durationRange = 1..300
    val selectedDuration = duration.coerceIn(durationRange)

    CompactMeasurementRow(
        title = "Workout duration",
        icon = Icons.Filled.Timer,
        valueText = "$selectedDuration min"
    ) {
        ScrollingNumberSelector("min", selectedDuration, durationRange, Modifier.fillMaxWidth()) {
            onChange(it)
        }
    }
}

@Composable
private fun CompactMeasurementRow(
    title: String,
    icon: ImageVector,
    valueText: String,
    content: @Composable () -> Unit
) {
    var expanded by rememberSaveable { mutableStateOf(false) }

    Column {
        ProfileSettingRow(
            title = title,
            icon = icon,
            modifier = Modifier.clickable { expanded = !expanded }
        ) {
            CompactValueLabel(value = valueText)
        }
        if (expanded) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 52.dp, bottom = 12.dp)
            ) {
                content()
            }
        }
    }
}

@Composable
private fun HeightMeasurementCompactRow(
    measurementSystem: MeasurementSystem,
    centimeters: Double,
    onChange: (Double) -> Unit
) {
    if (measurementSystem == MeasurementSystem.Metric) {
        val parts = splitDecimal(centimeters, 120..230)
        CompactMeasurementRow(
            title = "Height",
            icon = Icons.Filled.Build,
            valueText = "${formatOneDecimal(combineDecimal(parts.whole, parts.decimal))} cm"
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ScrollingNumberSelector("cm", parts.whole, 120..230, Modifier.weight(1f)) {
                    onChange(combineDecimal(it, parts.decimal))
                }
                ScrollingNumberSelector("decimal", parts.decimal, 0..9, Modifier.weight(1f), display = { ".$it" }) {
                    onChange(combineDecimal(parts.whole, it))
                }
            }
        }
    } else {
        val parts = splitImperialHeight(centimeters)
        CompactMeasurementRow(
            title = "Height",
            icon = Icons.Filled.Build,
            valueText = "${parts.feet} ft ${parts.inches} in"
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ScrollingNumberSelector("feet", parts.feet, 3..8, Modifier.weight(1f)) {
                    onChange(imperialHeightToCentimeters(it, parts.inches))
                }
                ScrollingNumberSelector("inches", parts.inches, 0..11, Modifier.weight(1f)) {
                    onChange(imperialHeightToCentimeters(parts.feet, it))
                }
            }
        }
    }
}

@Composable
private fun WeightMeasurementCompactRow(
    title: String = "Weight",
    icon: ImageVector = Icons.Filled.FitnessCenter,
    measurementSystem: MeasurementSystem,
    kilograms: Double,
    onChange: (Double) -> Unit
) {
    val displayValue = if (measurementSystem == MeasurementSystem.Metric) kilograms else kilograms * 2.2046226218
    val range = if (measurementSystem == MeasurementSystem.Metric) 30..250 else 66..551
    val unit = if (measurementSystem == MeasurementSystem.Metric) "kg" else "lb"
    val parts = splitDecimal(displayValue, range)

    CompactMeasurementRow(
        title = title,
        icon = icon,
        valueText = "${formatOneDecimal(combineDecimal(parts.whole, parts.decimal))} $unit"
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ScrollingNumberSelector(unit, parts.whole, range, Modifier.weight(1f)) { selectedWhole ->
                val nextValue = combineDecimal(selectedWhole, parts.decimal)
                onChange(if (measurementSystem == MeasurementSystem.Metric) nextValue else nextValue / 2.2046226218)
            }
            ScrollingNumberSelector("decimal", parts.decimal, 0..9, Modifier.weight(1f), display = { ".$it" }) { selectedDecimal ->
                val nextValue = combineDecimal(parts.whole, selectedDecimal)
                onChange(if (measurementSystem == MeasurementSystem.Metric) nextValue else nextValue / 2.2046226218)
            }
        }
    }
}

@Composable
private fun PercentMeasurementCompactRow(
    title: String,
    icon: ImageVector,
    value: Double,
    range: IntRange,
    onChange: (Double) -> Unit
) {
    val parts = splitDecimal(value, range)
    CompactMeasurementRow(
        title = title,
        icon = icon,
        valueText = "${formatOneDecimal(combineDecimal(parts.whole, parts.decimal))}%"
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ScrollingNumberSelector("%", parts.whole, range, Modifier.weight(1f)) {
                onChange(combineDecimal(it, parts.decimal))
            }
            ScrollingNumberSelector("decimal", parts.decimal, 0..9, Modifier.weight(1f), display = { ".$it" }) {
                onChange(combineDecimal(parts.whole, it))
            }
        }
    }
}

@Composable
private fun NumberStepper(
    title: String,
    value: Int,
    suffix: String,
    modifier: Modifier = Modifier,
    onChange: (Int) -> Unit
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.36f)),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.26f))
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(title, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                IconStepper(Icons.Filled.Close) { onChange(value - 1) }
                Text(
                    text = if (suffix.isBlank()) value.toString() else "$value $suffix",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onBackground
                )
                IconStepper(Icons.Filled.Add) { onChange(value + 1) }
            }
        }
    }
}

@Composable
private fun MeasurementSystemSelector(
    selected: MeasurementSystem,
    modifier: Modifier = Modifier,
    onSelect: (MeasurementSystem) -> Unit
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.42f)),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.28f))
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(9.dp)) {
            Text(
                text = "Units",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                MeasurementSystem.values().forEach { system ->
                    val isSelected = selected == system
                    Text(
                        text = system.title,
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(14.dp))
                            .clickable { onSelect(system) }
                            .background(if (isSelected) DeltsAccent else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.46f))
                            .padding(horizontal = 8.dp, vertical = 9.dp),
                        style = MaterialTheme.typography.labelLarge,
                        color = if (isSelected) DeltsOnAccent else MaterialTheme.colorScheme.onBackground,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }
    }
}

@Composable
private fun HeightMeasurementPicker(
    measurementSystem: MeasurementSystem,
    centimeters: Double,
    modifier: Modifier = Modifier,
    onChange: (Double) -> Unit
) {
    if (measurementSystem == MeasurementSystem.Metric) {
        val parts = splitDecimal(centimeters, 120..230)
        MeasurementPickerCard(
            title = "Height",
            valueText = "${formatOneDecimal(combineDecimal(parts.whole, parts.decimal))} cm",
            modifier = modifier
        ) {
            ScrollingNumberSelector(
                label = "cm",
                value = parts.whole,
                values = 120..230,
                modifier = Modifier.weight(1f)
            ) { onChange(combineDecimal(it, parts.decimal)) }
            ScrollingNumberSelector(
                label = "decimal",
                value = parts.decimal,
                values = 0..9,
                modifier = Modifier.weight(1f),
                display = { ".$it" }
            ) { onChange(combineDecimal(parts.whole, it)) }
        }
    } else {
        val parts = splitImperialHeight(centimeters)
        MeasurementPickerCard(
            title = "Height",
            valueText = "${parts.feet} ft ${parts.inches} in",
            modifier = modifier
        ) {
            ScrollingNumberSelector(
                label = "feet",
                value = parts.feet,
                values = 3..8,
                modifier = Modifier.weight(1f)
            ) { onChange(imperialHeightToCentimeters(it, parts.inches)) }
            ScrollingNumberSelector(
                label = "inches",
                value = parts.inches,
                values = 0..11,
                modifier = Modifier.weight(1f)
            ) { onChange(imperialHeightToCentimeters(parts.feet, it)) }
        }
    }
}

@Composable
private fun WeightMeasurementPicker(
    measurementSystem: MeasurementSystem,
    kilograms: Double,
    modifier: Modifier = Modifier,
    onChange: (Double) -> Unit
) {
    val displayValue = if (measurementSystem == MeasurementSystem.Metric) kilograms else kilograms * 2.2046226218
    val range = if (measurementSystem == MeasurementSystem.Metric) 30..250 else 66..551
    val unit = if (measurementSystem == MeasurementSystem.Metric) "kg" else "lb"
    val parts = splitDecimal(displayValue, range)

    MeasurementPickerCard(
        title = "Weight",
        valueText = "${formatOneDecimal(combineDecimal(parts.whole, parts.decimal))} $unit",
        modifier = modifier
    ) {
        ScrollingNumberSelector(
            label = unit,
            value = parts.whole,
            values = range,
            modifier = Modifier.weight(1f)
        ) { selectedWhole ->
            val nextValue = combineDecimal(selectedWhole, parts.decimal)
            onChange(if (measurementSystem == MeasurementSystem.Metric) nextValue else nextValue / 2.2046226218)
        }
        ScrollingNumberSelector(
            label = "decimal",
            value = parts.decimal,
            values = 0..9,
            modifier = Modifier.weight(1f),
            display = { ".$it" }
        ) { selectedDecimal ->
            val nextValue = combineDecimal(parts.whole, selectedDecimal)
            onChange(if (measurementSystem == MeasurementSystem.Metric) nextValue else nextValue / 2.2046226218)
        }
    }
}

@Composable
private fun PercentMeasurementPicker(
    title: String,
    value: Double,
    range: IntRange,
    modifier: Modifier = Modifier,
    onChange: (Double) -> Unit
) {
    val parts = splitDecimal(value, range)
    MeasurementPickerCard(
        title = title,
        valueText = "${formatOneDecimal(combineDecimal(parts.whole, parts.decimal))}%",
        modifier = modifier
    ) {
        ScrollingNumberSelector(
            label = "%",
            value = parts.whole,
            values = range,
            modifier = Modifier.weight(1f)
        ) { onChange(combineDecimal(it, parts.decimal)) }
        ScrollingNumberSelector(
            label = "decimal",
            value = parts.decimal,
            values = 0..9,
            modifier = Modifier.weight(1f),
            display = { ".$it" }
        ) { onChange(combineDecimal(parts.whole, it)) }
    }
}

@Composable
private fun MeasurementPickerCard(
    title: String,
    valueText: String,
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.42f),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.28f))
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(11.dp)) {
            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = title,
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = valueText,
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onBackground,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), content = content)
        }
    }
}

@Composable
private fun ScrollingNumberSelector(
    label: String,
    value: Int,
    values: IntRange,
    modifier: Modifier = Modifier,
    display: (Int) -> String = { it.toString() },
    onSelect: (Int) -> Unit
) {
    var expanded by rememberSaveable { mutableStateOf(false) }
    val selectedValue = value.coerceIn(values.first, values.last)

    Box(modifier = modifier) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(15.dp))
                .clickable { expanded = true }
                .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.46f))
                .padding(horizontal = 10.dp, vertical = 9.dp),
            verticalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = display(selectedValue),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                maxLines = 1
            )
        }

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier.heightIn(max = 320.dp)
        ) {
            values.forEach { option ->
                DropdownMenuItem(
                    text = { Text(display(option), style = MaterialTheme.typography.bodyLarge) },
                    leadingIcon = if (option == selectedValue) {
                        {
                            Icon(
                                imageVector = Icons.Filled.Check,
                                contentDescription = null,
                                tint = DeltsAccent,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    } else {
                        null
                    },
                    onClick = {
                        onSelect(option)
                        expanded = false
                    }
                )
            }
        }
    }
}

private data class DecimalParts(val whole: Int, val decimal: Int)

private data class ImperialHeightParts(val feet: Int, val inches: Int)

private fun splitDecimal(value: Double, range: IntRange): DecimalParts {
    val minimumTenths = range.first * 10
    val maximumTenths = (range.last * 10) + 9
    val tenths = (value * 10).roundToInt().coerceIn(minimumTenths, maximumTenths)
    return DecimalParts(
        whole = (tenths / 10).coerceIn(range.first, range.last),
        decimal = tenths % 10
    )
}

private fun combineDecimal(whole: Int, decimal: Int): Double =
    whole.toDouble() + (decimal.coerceIn(0, 9).toDouble() / 10.0)

private fun splitImperialHeight(centimeters: Double): ImperialHeightParts {
    val totalInches = (centimeters / 2.54).roundToInt().coerceIn(36, 107)
    val feet = (totalInches / 12).coerceIn(3, 8)
    return ImperialHeightParts(
        feet = feet,
        inches = (totalInches - (feet * 12)).coerceIn(0, 11)
    )
}

private fun imperialHeightToCentimeters(feet: Int, inches: Int): Double {
    val totalInches = ((feet * 12) + inches).toDouble()
    return totalInches * 2.54
}

@Composable
private fun IconStepper(icon: ImageVector, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(32.dp)
            .clip(CircleShape)
            .clickable(onClick = onClick)
            .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.60f)),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onBackground, modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun DeltsGlassLabel(title: String, icon: ImageVector, dark: Boolean = true) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(if (dark) Color.Black.copy(alpha = 0.26f) else DeltsSecondaryAccent.copy(alpha = 0.11f))
            .padding(horizontal = 10.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Icon(icon, contentDescription = null, tint = if (dark) Color.White.copy(alpha = 0.84f) else DeltsSecondaryAccent, modifier = Modifier.size(14.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
            color = if (dark) Color.White.copy(alpha = 0.84f) else DeltsSecondaryAccent,
            maxLines = 1
        )
    }
}

@Composable
private fun DeltsScreenBackground(content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        content()
    }
}

private fun buildPlan(
    primaryMuscle: String?,
    level: String?,
    rawEquipment: String?,
    category: String?,
    exerciseLibrary: List<ExerciseItem>
): List<ExercisePlan> {
    val base = exerciseLibrary
        .filter { item ->
            (primaryMuscle?.let { item.primaryMuscles.contains(it) } ?: true) &&
                (level == null || item.level == level) &&
                (rawEquipment == null || item.rawEquipment == rawEquipment) &&
                (category == null || item.category == category)
        }

    return base.take(5).map { item ->
        ExercisePlan(
            name = item.name,
            primaryMuscles = item.primaryMuscles,
            rawEquipment = item.rawEquipment,
            level = item.level,
            category = item.category,
            imagePaths = item.imagePaths
        )
    }
}

private fun toggleInSet(set: Set<String>, item: String): Set<String> =
    if (set.contains(item)) set - item else set + item

private fun toggleInList(list: List<String>, item: String): List<String> =
    if (list.contains(item)) list - item else list + item

private val AndroidProfile.displayName: String
    get() = name.trim().ifEmpty { "Athlete" }

private fun SharedPreferences.loadWeeklyRoutine(): List<RoutineDay> {
    val raw = getString("weekly_routine_v1", null) ?: return defaultRoutineDays
    return runCatching {
        val array = JSONArray(raw)
        buildList {
            for (index in 0 until array.length()) {
                val dayObject = array.getJSONObject(index)
                val exercises = dayObject.optJSONArray("exercises").routineExercises()
                add(
                    RoutineDay(
                        name = dayObject.optString("name"),
                        shortName = dayObject.optString("shortName"),
                        bodyPart = dayObject.optString("bodyPart", anyRoutineBodyPart),
                        exercises = exercises
                    )
                )
            }
        }.takeIf { it.size == 7 } ?: defaultRoutineDays
    }.getOrElse { defaultRoutineDays }
}

private fun SharedPreferences.saveWeeklyRoutine(days: List<RoutineDay>) {
    val array = JSONArray()
    days.forEach { day ->
        array.put(
            JSONObject()
                .put("name", day.name)
                .put("shortName", day.shortName)
                .put("bodyPart", day.bodyPart)
                .put("exercises", JSONArray().apply {
                    day.exercises.forEach { exercise ->
                        put(exercise.toJSON())
                    }
                })
        )
    }
    edit().putString("weekly_routine_v1", array.toString()).apply()
}

private fun SharedPreferences.loadWorkoutHistory(): List<WorkoutHistoryRecord> {
    val raw = getString("workout_history_v1", null) ?: return emptyList()
    return runCatching {
        val array = JSONArray(raw)
        buildList {
            for (index in 0 until array.length()) {
                add(array.getJSONObject(index).toWorkoutHistoryRecord())
            }
        }
    }.getOrElse { emptyList() }
}

private fun SharedPreferences.saveWorkoutHistory(records: List<WorkoutHistoryRecord>) {
    val array = JSONArray()
    records.forEach { record -> array.put(record.toJSON()) }
    edit().putString("workout_history_v1", array.toString()).apply()
}

private fun SharedPreferences.loadMetricSnapshots(): List<MetricSnapshot> {
    val raw = getString("metric_snapshots_v1", null) ?: return emptyList()
    return runCatching {
        val array = JSONArray(raw)
        buildList {
            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                add(
                    MetricSnapshot(
                        id = item.optString("id", UUID.randomUUID().toString()),
                        dateMs = item.optLong("dateMs"),
                        weightKg = item.optDouble("weightKg"),
                        bodyFat = item.optDouble("bodyFat")
                    )
                )
            }
        }
    }.getOrElse { emptyList() }
}

private fun SharedPreferences.saveMetricSnapshots(snapshots: List<MetricSnapshot>) {
    val array = JSONArray()
    snapshots.sortedBy { it.dateMs }.forEach { snapshot ->
        array.put(snapshot.toJSON())
    }
    edit().putString("metric_snapshots_v1", array.toString()).apply()
}

private fun SharedPreferences.recordMetricSnapshot(profile: AndroidProfile): List<MetricSnapshot> {
    val todayStartMs = java.util.Calendar.getInstance().apply {
        set(java.util.Calendar.HOUR_OF_DAY, 0)
        set(java.util.Calendar.MINUTE, 0)
        set(java.util.Calendar.SECOND, 0)
        set(java.util.Calendar.MILLISECOND, 0)
    }.timeInMillis
    val now = System.currentTimeMillis()
    val snapshots = loadMetricSnapshots().toMutableList()
    val todayIndex = snapshots.indexOfFirst { it.dateMs >= todayStartMs }
    if (todayIndex >= 0) {
        snapshots[todayIndex] = snapshots[todayIndex].copy(dateMs = now, weightKg = profile.weightKg, bodyFat = profile.currentBodyFat)
    } else {
        snapshots.add(MetricSnapshot(dateMs = now, weightKg = profile.weightKg, bodyFat = profile.currentBodyFat))
    }
    saveMetricSnapshots(snapshots)
    return snapshots.sortedBy { it.dateMs }
}

private fun MetricSnapshot.toJSON(): JSONObject =
    JSONObject()
        .put("id", id)
        .put("dateMs", dateMs)
        .put("weightKg", weightKg)
        .put("bodyFat", bodyFat)

private fun upsertMetricSnapshot(snapshots: List<MetricSnapshot>, snapshot: MetricSnapshot): List<MetricSnapshot> {
    val dayStart = dayStartMs(snapshot.dateMs)
    val dayEnd = dayStart + 24L * 60L * 60L * 1000L
    val mutable = snapshots.toMutableList()
    val index = mutable.indexOfFirst { it.dateMs in dayStart until dayEnd }
    if (index >= 0) {
        mutable[index] = mutable[index].copy(
            dateMs = snapshot.dateMs,
            weightKg = snapshot.weightKg,
            bodyFat = snapshot.bodyFat
        )
    } else {
        mutable.add(snapshot)
    }
    return mutable.sortedBy { it.dateMs }
}

private fun updateMetricSnapshot(snapshots: List<MetricSnapshot>, snapshot: MetricSnapshot): List<MetricSnapshot> =
    snapshots.map { if (it.id == snapshot.id) snapshot else it }.sortedBy { it.dateMs }

private fun deleteMetricSnapshot(snapshots: List<MetricSnapshot>, id: String): List<MetricSnapshot> =
    snapshots.filterNot { it.id == id }.sortedBy { it.dateMs }

private fun dayStartMs(dateMs: Long): Long =
    java.util.Calendar.getInstance().apply {
        timeInMillis = dateMs
        set(java.util.Calendar.HOUR_OF_DAY, 0)
        set(java.util.Calendar.MINUTE, 0)
        set(java.util.Calendar.SECOND, 0)
        set(java.util.Calendar.MILLISECOND, 0)
    }.timeInMillis

private fun SharedPreferences.loadProfile(): AndroidProfile {
    val mainGoal = getString("profile_goal", "Muscle Gain").orEmpty()
    val extraGoals = getString("profile_extra_goals", "").orEmpty()
    val defaultGoals = buildSet {
        add(mainGoal)
        if (extraGoals.isNotBlank()) {
            add(otherGoalOption)
        }
    }
    val selectedGoals = getStringSet("profile_goals", defaultGoals) ?: defaultGoals
    val storedDatasetLevel = getString("profile_experience", "Intermediate").orEmpty()
    val weightKg = getDoubleCompat("profile_weight_kg", getDoubleCompat("profile_weight", 75.0))

    return AndroidProfile(
        name = getString("profile_name", "Athlete").orEmpty(),
        gender = getString("profile_gender", "Male").orEmpty().ifBlank { "Male" },
        age = getInt("profile_age", 24),
        heightCm = getDoubleCompat("profile_height_cm", 178.0),
        weightKg = weightKg,
        goalWeightKg = getDoubleCompat("profile_goal_weight_kg", weightKg),
        currentBodyFat = getDoubleCompat("profile_bodyfat_current", 18.0),
        desiredBodyFat = getDoubleCompat("profile_bodyfat_desired", 12.0),
        experience = if (storedDatasetLevel == "Advanced") "Expert" else storedDatasetLevel,
        mainGoal = mainGoal,
        selectedGoals = selectedGoals,
        extraGoals = extraGoals,
        extraIssues = getString("profile_extra_issues", "").orEmpty(),
        frequency = getInt("profile_frequency", 4),
        workoutSplit = getString("profile_workout_split", "Push Pull Legs").orEmpty(),
        customWorkoutSplit = getString("profile_custom_workout_split", "").orEmpty(),
        duration = getInt("profile_duration", 60),
        availableEquipment = getStringSet("profile_equipment", setOf("Dumbbells", "Bench", "Cable Machine")) ?: emptySet(),
        bodyFocus = normalizeTargetMuscleSelection(getStringSet("profile_focus", setOf("Chest", "Shoulders", "Back")) ?: emptySet()),
        issues = getStringSet("profile_issues", emptySet()) ?: emptySet()
    )
}

private fun SharedPreferences.saveProfile(profile: AndroidProfile) {
    edit()
        .putString("profile_name", profile.name)
        .putString("profile_gender", profile.gender)
        .putInt("profile_age", profile.age)
        .putString("profile_height_cm", formatOneDecimal(profile.heightCm))
        .putString("profile_weight_kg", formatOneDecimal(profile.weightKg))
        .putString("profile_goal_weight_kg", formatOneDecimal(profile.goalWeightKg))
        .putInt("profile_weight", profile.weightKg.roundToInt())
        .putString("profile_bodyfat_current", formatOneDecimal(profile.currentBodyFat))
        .putString("profile_bodyfat_desired", formatOneDecimal(profile.desiredBodyFat))
        .putString("profile_experience", profile.experience)
        .putString("profile_goal", profile.mainGoal)
        .putStringSet("profile_goals", profile.selectedGoals)
        .putString("profile_extra_goals", profile.extraGoals)
        .putString("profile_extra_issues", profile.extraIssues)
        .putInt("profile_frequency", profile.frequency)
        .putString("profile_workout_split", profile.workoutSplit)
        .putString("profile_custom_workout_split", profile.customWorkoutSplit)
        .putInt("profile_duration", profile.duration)
        .putStringSet("profile_equipment", profile.availableEquipment)
        .putStringSet("profile_focus", normalizeTargetMuscleSelection(profile.bodyFocus))
        .putStringSet("profile_issues", profile.issues)
        .apply()
}

private fun SharedPreferences.getDoubleCompat(key: String, defaultValue: Double): Double {
    return when (val value = all[key]) {
        is Number -> value.toDouble()
        is String -> value.toDoubleOrNull() ?: defaultValue
        else -> defaultValue
    }
}

private fun formatOneDecimal(value: Double): String =
    String.format(Locale.US, "%.1f", value)

private fun SharedPreferences.loadMeasurementSystem(): MeasurementSystem =
    MeasurementSystem.values().firstOrNull { it.name == getString("profile_measurement_system", MeasurementSystem.Metric.name) }
        ?: MeasurementSystem.Metric

private fun SharedPreferences.saveMeasurementSystem(system: MeasurementSystem) {
    edit().putString("profile_measurement_system", system.name).apply()
}

private fun SharedPreferences.loadAISettings(): AISettings =
    AISettings(
        provider = getString("profile_ai_provider", "Gemini").orEmpty(),
        customProvider = getString("profile_ai_custom_provider", "").orEmpty(),
        model = getString("profile_ai_model", defaultModelForProvider("Gemini")).orEmpty(),
        customModel = getString("profile_ai_custom_model", "").orEmpty(),
        fallbackEnabled = getBoolean("profile_ai_fallback_enabled", false),
        fallbackProvider = getString("profile_ai_fallback_provider", "OpenRouter").orEmpty(),
        fallbackCustomProvider = getString("profile_ai_fallback_custom_provider", "").orEmpty(),
        fallbackModel = getString("profile_ai_fallback_model", defaultModelForProvider("OpenRouter")).orEmpty(),
        fallbackCustomModel = getString("profile_ai_fallback_custom_model", "").orEmpty()
    ).normalized()

private fun SharedPreferences.saveAISettings(settings: AISettings) {
    edit()
        .putString("profile_ai_provider", settings.provider)
        .putString("profile_ai_custom_provider", settings.customProvider)
        .putString("profile_ai_model", settings.model)
        .putString("profile_ai_custom_model", settings.customModel)
        .putBoolean("profile_ai_fallback_enabled", settings.fallbackEnabled)
        .putString("profile_ai_fallback_provider", settings.fallbackProvider)
        .putString("profile_ai_fallback_custom_provider", settings.fallbackCustomProvider)
        .putString("profile_ai_fallback_model", settings.fallbackModel)
        .putString("profile_ai_fallback_custom_model", settings.fallbackCustomModel)
        .apply()
}

private enum class DeltsTab(val title: String, val icon: ImageVector) {
    Start("Start", Icons.Filled.PlayArrow),
    Workouts("Workouts", Icons.Filled.List),
    Progress("Progress", Icons.Filled.History),
    Profile("Profile", Icons.Filled.Person)
}

private enum class MeasurementSystem(val title: String) {
    Metric("Metric"),
    Imperial("Imperial");

    val weightUnit: String
        get() = if (this == Metric) "kg" else "lb"
}

private enum class MetricDialogType {
    Weight,
    BodyFat
}

private enum class LibrarySort(val title: String) {
    Name("Name"),
    Level("Level"),
    PrimaryMuscles("Primary"),
    SecondaryMuscles("Secondary"),
    Category("Category"),
    Force("Force"),
    Mechanic("Mechanic"),
    RawEquipment("Equipment")
}

private data class AndroidProfile(
    val name: String,
    val gender: String,
    val age: Int,
    val heightCm: Double,
    val weightKg: Double,
    val goalWeightKg: Double,
    val currentBodyFat: Double,
    val desiredBodyFat: Double,
    val experience: String,
    val mainGoal: String,
    val selectedGoals: Set<String>,
    val extraGoals: String,
    val extraIssues: String,
    val frequency: Int,
    val workoutSplit: String,
    val customWorkoutSplit: String,
    val duration: Int,
    val availableEquipment: Set<String>,
    val bodyFocus: Set<String>,
    val issues: Set<String>
)

private data class AISettings(
    val provider: String,
    val customProvider: String,
    val model: String,
    val customModel: String,
    val fallbackEnabled: Boolean,
    val fallbackProvider: String,
    val fallbackCustomProvider: String,
    val fallbackModel: String,
    val fallbackCustomModel: String
) {
    fun normalized(): AISettings {
        val safeProvider = provider.takeIf { aiProviderOptions.contains(it) } ?: customAIProvider
        val safeFallbackProvider = fallbackProvider.takeIf { aiProviderOptions.contains(it) } ?: customAIProvider
        val safeModel = model.takeIf { modelOptionsForProvider(safeProvider).contains(it) }
            ?: defaultModelForProvider(safeProvider)
        val safeFallbackModel = fallbackModel.takeIf { modelOptionsForProvider(safeFallbackProvider).contains(it) }
            ?: defaultModelForProvider(safeFallbackProvider)

        return copy(
            provider = safeProvider,
            model = safeModel,
            fallbackProvider = safeFallbackProvider,
            fallbackModel = safeFallbackModel
        )
    }

    fun withProvider(nextProvider: String): AISettings =
        copy(provider = nextProvider, model = defaultModelForProvider(nextProvider)).normalized()

    fun withFallbackProvider(nextProvider: String): AISettings =
        copy(fallbackProvider = nextProvider, fallbackModel = defaultModelForProvider(nextProvider)).normalized()
}

private data class DeltsOption(
    val title: String,
    val detail: String,
    val icon: ImageVector
)

private data class ExerciseItem(
    val name: String,
    val level: String,
    val imagePaths: List<String>,
    val force: String = "Unspecified",
    val mechanic: String = "Unspecified",
    val category: String = "Unspecified",
    val rawEquipment: String = "Unspecified",
    val primaryMuscles: List<String> = emptyList(),
    val secondaryMuscles: List<String> = emptyList(),
    val instructions: List<String> = emptyList()
)

private data class ExercisePlan(
    val name: String,
    val primaryMuscles: List<String>,
    val rawEquipment: String,
    val level: String,
    val category: String,
    val imagePaths: List<String>
)

private const val anyRoutineBodyPart = "Any"

private data class RoutineDay(
    val name: String,
    val shortName: String,
    val bodyPart: String,
    val exercises: List<RoutineExercise> = emptyList()
)

private data class RoutineExercise(
    val id: String = UUID.randomUUID().toString(),
    val itemId: String,
    val name: String,
    val primaryMuscles: List<String>,
    val rawEquipment: String,
    val level: String,
    val category: String,
    val imagePaths: List<String>,
    val instructions: List<String>,
    val sets: Int = 1,
    val reps: String = ""
) {
    companion object {
        fun from(item: ExerciseItem): RoutineExercise =
            RoutineExercise(
                itemId = item.name,
                name = item.name,
                primaryMuscles = item.primaryMuscles,
                rawEquipment = item.rawEquipment,
                level = item.level,
                category = item.category,
                imagePaths = item.imagePaths,
                instructions = item.instructions
            )
    }
}

private data class ActiveWorkoutSession(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val bodyPart: String,
    val startedAtMs: Long,
    val exercises: List<ActiveExerciseLog>
) {
    companion object {
        fun from(title: String, bodyPart: String, exercises: List<RoutineExercise>, startedAtMs: Long): ActiveWorkoutSession =
            ActiveWorkoutSession(
                title = title,
                bodyPart = bodyPart,
                startedAtMs = startedAtMs,
                exercises = exercises.map { exercise ->
                    ActiveExerciseLog(
                        id = exercise.id,
                        name = exercise.name,
                        primaryMuscles = exercise.primaryMuscles,
                        rawEquipment = exercise.rawEquipment,
                        level = exercise.level,
                        imagePaths = exercise.imagePaths,
                        sets = (1..exercise.sets.coerceAtLeast(1)).map { setNumber ->
                            ActiveSetLog(setNumber = setNumber, reps = exercise.reps)
                        }
                    )
                }
            )
    }

    fun toHistoryRecord(finishedAtMs: Long): WorkoutHistoryRecord {
        val elapsedMs = (finishedAtMs - startedAtMs).coerceAtLeast(0)
        return WorkoutHistoryRecord(
            id = id,
            title = title,
            bodyPart = bodyPart,
            startedAtMs = startedAtMs,
            endedAtMs = finishedAtMs,
            durationMinutes = ((elapsedMs + 59_999L) / 60_000L).toInt().coerceAtLeast(1),
            exercises = exercises.map { exercise ->
                CompletedExerciseRecord(
                    name = exercise.name,
                    primaryMuscles = exercise.primaryMuscles,
                    rawEquipment = exercise.rawEquipment,
                    sets = exercise.sets.map { set ->
                        CompletedSetRecord(
                            setNumber = set.setNumber,
                            completed = set.completed,
                            weight = set.weight,
                            reps = set.reps,
                            elapsedSeconds = set.elapsedSeconds
                        )
                    }
                )
            }
        )
    }
}

private data class ActiveExerciseLog(
    val id: String,
    val name: String,
    val primaryMuscles: List<String>,
    val rawEquipment: String,
    val level: String,
    val imagePaths: List<String>,
    val sets: List<ActiveSetLog>
)

private data class ActiveSetLog(
    val setNumber: Int,
    val weight: String = "",
    val reps: String = "",
    val completed: Boolean = false,
    val elapsedSeconds: Int? = null
)

private data class WorkoutHistoryRecord(
    val id: String,
    val title: String,
    val bodyPart: String,
    val startedAtMs: Long,
    val endedAtMs: Long,
    val durationMinutes: Int,
    val exercises: List<CompletedExerciseRecord>
)

private data class CompletedExerciseRecord(
    val name: String,
    val primaryMuscles: List<String>,
    val rawEquipment: String,
    val sets: List<CompletedSetRecord>
)

private data class CompletedSetRecord(
    val setNumber: Int,
    val completed: Boolean,
    val weight: String,
    val reps: String,
    val elapsedSeconds: Int?
)

private data class MetricSnapshot(
    val id: String = UUID.randomUUID().toString(),
    val dateMs: Long,
    val weightKg: Double,
    val bodyFat: Double
)

private enum class ProgressRange(val title: String, private val durationMs: Long?) {
    Week("Week", 7L * 24L * 60L * 60L * 1000L),
    Month("Month", 31L * 24L * 60L * 60L * 1000L),
    ThreeMonths("3M", 93L * 24L * 60L * 60L * 1000L),
    SixMonths("6M", 186L * 24L * 60L * 60L * 1000L),
    Year("1Y", 366L * 24L * 60L * 60L * 1000L),
    All("All", null);

    private fun startMs(): Long? = durationMs?.let { System.currentTimeMillis() - it }

    val averagePeriodMs: Long?
        get() = durationMs

    fun filterSnapshots(snapshots: List<MetricSnapshot>): List<MetricSnapshot> {
        val start = startMs() ?: return snapshots
        return snapshots.filter { it.dateMs >= start }
    }

    fun filterWorkouts(workouts: List<WorkoutHistoryRecord>): List<WorkoutHistoryRecord> {
        val start = startMs() ?: return workouts
        return workouts.filter { it.startedAtMs >= start }
    }
}

private val defaultRoutineDays = listOf(
    RoutineDay("Monday", "Mon", "Chest"),
    RoutineDay("Tuesday", "Tue", "Back"),
    RoutineDay("Wednesday", "Wed", "Legs"),
    RoutineDay("Thursday", "Thu", "Shoulders"),
    RoutineDay("Friday", "Fri", "Arms"),
    RoutineDay("Saturday", "Sat", "Abdominals"),
    RoutineDay("Sunday", "Sun", anyRoutineBodyPart)
)

private fun todayRoutineIndex(): Int {
    val calendar = java.util.Calendar.getInstance()
    return (calendar.get(java.util.Calendar.DAY_OF_WEEK) + 5) % 7
}

private fun elapsedDisplay(seconds: Int): String {
    val safeSeconds = seconds.coerceAtLeast(0)
    return String.format(Locale.US, "%d:%02d", safeSeconds / 60, safeSeconds % 60)
}

private fun loadFreeExerciseDB(assets: AssetManager): List<ExerciseItem> = runCatching {
    val rawJSON = assets.open("dist/exercises.json").bufferedReader().use { it.readText() }
    val records = JSONArray(rawJSON)

    buildList {
        for (index in 0 until records.length()) {
            val record = records.getJSONObject(index)
            val name = record.optString("name").trim()
            if (name.isEmpty()) {
                continue
            }

            val primaryMuscles = record.optJSONArray("primaryMuscles").stringList()
            val secondaryMuscles = record.optJSONArray("secondaryMuscles").stringList()
            val rawEquipment = metadataTitle(record.optString("equipment"))
            val instructions = record.optJSONArray("instructions").stringList()

            add(
                ExerciseItem(
                    name = name,
                    level = metadataTitle(record.optString("level")),
                    imagePaths = record.optJSONArray("images").stringList(),
                    force = metadataTitle(record.optString("force")),
                    mechanic = metadataTitle(record.optString("mechanic")),
                    category = metadataTitle(record.optString("category")),
                    rawEquipment = rawEquipment,
                    primaryMuscles = primaryMuscles.map(::metadataTitle).filter { it != "Unspecified" },
                    secondaryMuscles = secondaryMuscles.map(::metadataTitle).filter { it != "Unspecified" },
                    instructions = instructions.ifEmpty { listOf("Move with control, keep your setup tight, and stop if form breaks.") }
                )
            )
        }
    }.sortedBy { it.name.lowercase() }
}.getOrElse {
    sampleExerciseLibrary
}

private fun JSONArray?.stringList(): List<String> {
    if (this == null) {
        return emptyList()
    }
    return buildList {
        for (index in 0 until length()) {
            val value = optString(index).trim()
            if (value.isNotEmpty()) {
                add(value)
            }
        }
    }
}

private fun JSONArray?.routineExercises(): List<RoutineExercise> {
    if (this == null) {
        return emptyList()
    }
    return buildList {
        for (index in 0 until length()) {
            val item = optJSONObject(index) ?: continue
            add(
                RoutineExercise(
                    id = item.optString("id", UUID.randomUUID().toString()),
                    itemId = item.optString("itemId"),
                    name = item.optString("name"),
                    primaryMuscles = item.optJSONArray("primaryMuscles").stringList(),
                    rawEquipment = item.optString("rawEquipment", "Unspecified"),
                    level = item.optString("level", "Unspecified"),
                    category = item.optString("category", "Unspecified"),
                    imagePaths = item.optJSONArray("imagePaths").stringList(),
                    instructions = item.optJSONArray("instructions").stringList(),
                    sets = item.optInt("sets", 1).coerceAtLeast(1),
                    reps = item.optString("reps")
                )
            )
        }
    }
}

private fun RoutineExercise.toJSON(): JSONObject =
    JSONObject()
        .put("id", id)
        .put("itemId", itemId)
        .put("name", name)
        .put("primaryMuscles", JSONArray(primaryMuscles))
        .put("rawEquipment", rawEquipment)
        .put("level", level)
        .put("category", category)
        .put("imagePaths", JSONArray(imagePaths))
        .put("instructions", JSONArray(instructions))
        .put("sets", sets)
        .put("reps", reps)

private fun WorkoutHistoryRecord.toJSON(): JSONObject =
    JSONObject()
        .put("id", id)
        .put("title", title)
        .put("bodyPart", bodyPart)
        .put("startedAtMs", startedAtMs)
        .put("endedAtMs", endedAtMs)
        .put("durationMinutes", durationMinutes)
        .put("exercises", JSONArray().apply {
            exercises.forEach { exercise ->
                put(
                    JSONObject()
                        .put("name", exercise.name)
                        .put("primaryMuscles", JSONArray(exercise.primaryMuscles))
                        .put("rawEquipment", exercise.rawEquipment)
                        .put("sets", JSONArray().apply {
                            exercise.sets.forEach { set ->
                                put(
                                    JSONObject()
                                        .put("setNumber", set.setNumber)
                                        .put("completed", set.completed)
                                        .put("weight", set.weight)
                                        .put("reps", set.reps)
                                        .put("elapsedSeconds", set.elapsedSeconds ?: JSONObject.NULL)
                                )
                            }
                        })
                )
            }
        })

private fun JSONObject.toWorkoutHistoryRecord(): WorkoutHistoryRecord {
    val exerciseArray = optJSONArray("exercises") ?: JSONArray()
    val exercises = buildList {
        for (exerciseIndex in 0 until exerciseArray.length()) {
            val exercise = exerciseArray.optJSONObject(exerciseIndex) ?: continue
            val setArray = exercise.optJSONArray("sets") ?: JSONArray()
            val sets = buildList {
                for (setIndex in 0 until setArray.length()) {
                    val set = setArray.optJSONObject(setIndex) ?: continue
                    add(
                        CompletedSetRecord(
                            setNumber = set.optInt("setNumber"),
                            completed = set.optBoolean("completed"),
                            weight = set.optString("weight"),
                            reps = set.optString("reps"),
                            elapsedSeconds = if (set.isNull("elapsedSeconds")) null else set.optInt("elapsedSeconds")
                        )
                    )
                }
            }
            add(
                CompletedExerciseRecord(
                    name = exercise.optString("name"),
                    primaryMuscles = exercise.optJSONArray("primaryMuscles").stringList(),
                    rawEquipment = exercise.optString("rawEquipment"),
                    sets = sets
                )
            )
        }
    }
    return WorkoutHistoryRecord(
        id = optString("id", UUID.randomUUID().toString()),
        title = optString("title"),
        bodyPart = optString("bodyPart"),
        startedAtMs = optLong("startedAtMs"),
        endedAtMs = optLong("endedAtMs"),
        durationMinutes = optInt("durationMinutes", 1),
        exercises = exercises
    )
}

private fun metadataTitle(value: String?): String {
    val trimmed = value?.trim().orEmpty()
    if (trimmed.isEmpty() || trimmed == "null") {
        return "Unspecified"
    }

    return trimmed
        .split(" ")
        .joinToString(" ") { word ->
            word.split("-").joinToString("-") { segment ->
                segment.replaceFirstChar { char ->
                    if (char.isLowerCase()) char.titlecase(Locale.US) else char.toString()
                }
            }
        }
}

private fun List<String>.distinctSorted(): List<String> =
    distinct()
        .filter { it.isNotBlank() }
        .sortedWith(String.CASE_INSENSITIVE_ORDER)

private fun List<String>.distinctSortedLevels(): List<String> =
    distinct()
        .filter { it.isNotBlank() }
        .sortedWith(
            compareBy<String> { levelSortRank(it) }
                .thenBy(String.CASE_INSENSITIVE_ORDER) { it }
        )

private fun LibrarySort.comparator(): Comparator<ExerciseItem> =
    when (this) {
        LibrarySort.Name -> compareBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Level -> compareBy<ExerciseItem> { levelSortRank(it.level) }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.PrimaryMuscles -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.primaryMusclesTitle() }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.SecondaryMuscles -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.secondaryMusclesTitle() }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Category -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.category }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Force -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.force }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Mechanic -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.mechanic }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.RawEquipment -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.rawEquipment }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
    }

private fun ExerciseItem.primaryMusclesTitle(): String =
    primaryMuscles.ifEmpty { listOf("Unspecified") }.joinToString(", ")

private fun ExerciseItem.secondaryMusclesTitle(): String =
    secondaryMuscles.ifEmpty { listOf("None") }.joinToString(", ")

private fun levelSortRank(level: String): Int =
    when (level) {
        "Beginner" -> 0
        "Intermediate" -> 1
        "Expert", "Advanced" -> 2
        else -> 3
    }

private fun ExerciseItem.databaseSummary(): String {
    val summary = listOf(category, force, mechanic)
        .filter { it != "Unspecified" }
        .joinToString(" - ")
        .ifBlank { rawEquipment }

    return summary
}

private fun ExerciseItem.searchableText(): String =
    listOf(
        name,
        level,
        force,
        mechanic,
        category,
        rawEquipment,
        primaryMuscles.joinToString(" "),
        secondaryMuscles.joinToString(" "),
        instructions.joinToString(" ")
    )
        .joinToString(" ")
        .lowercase(Locale.US)

private const val customAIProvider = "Custom"
private const val customAIModel = "Custom model"

private val aiProviderOptions = listOf(
    "Gemini",
    "OpenAI",
    "Anthropic Claude",
    "xAI Grok",
    "OpenRouter",
    "Together AI",
    "Groq",
    "Hugging Face",
    "Fireworks AI",
    "DeepInfra",
    "Mistral",
    "Ollama",
    customAIProvider
)

private val aiModelsByProvider = mapOf(
    "Gemini" to listOf(
        "gemini-3.5-flash",
        "gemini-3.1-pro",
        "gemini-3-flash",
        "gemini-2.5-pro",
        "gemini-2.5-flash"
    ),
    "OpenAI" to listOf(
        "gpt-5.5",
        "gpt-5.4",
        "gpt-5.4-mini",
        "gpt-5.4-nano",
        "gpt-5",
        "gpt-5-mini",
        "gpt-4.1"
    ),
    "Anthropic Claude" to listOf(
        "claude-opus-4-7",
        "claude-sonnet-4-6",
        "claude-haiku-4-5-20251001",
        "claude-opus-4-6",
        "claude-sonnet-4-5"
    ),
    "xAI Grok" to listOf(
        "grok-4.3",
        "grok-4.3-latest",
        "grok-build-0.1",
        "grok-4"
    ),
    "OpenRouter" to listOf(
        "openrouter/auto",
        "google/gemini-2.5-pro",
        "anthropic/claude-sonnet-4.5",
        "openai/gpt-5",
        "x-ai/grok-4"
    ),
    "Together AI" to listOf(
        "moonshotai/Kimi-K2.5",
        "zai-org/GLM-5.1",
        "openai/gpt-oss-120b",
        "deepseek-ai/DeepSeek-R1",
        "Qwen/Qwen3-Coder-480B-A35B-Instruct-FP8"
    ),
    "Groq" to listOf(
        "openai/gpt-oss-120b",
        "openai/gpt-oss-20b",
        "meta-llama/llama-4-maverick-17b-128e-instruct",
        "meta-llama/llama-4-scout-17b-16e-instruct",
        "llama-3.3-70b-versatile"
    ),
    "Hugging Face" to listOf(
        "openai/gpt-oss-120b:fastest",
        "Qwen/Qwen3-235B-A22B:fastest",
        "deepseek-ai/DeepSeek-V3.1:fastest",
        "meta-llama/Llama-4-Maverick-17B-128E-Instruct:fastest"
    ),
    "Fireworks AI" to listOf(
        "accounts/fireworks/models/kimi-k2-instruct-0905",
        "accounts/fireworks/models/deepseek-v3p1",
        "accounts/fireworks/models/deepseek-r1",
        "accounts/fireworks/models/qwen3-235b-a22b",
        "accounts/fireworks/models/llama-v3p1-405b-instruct"
    ),
    "DeepInfra" to listOf(
        "deepseek-ai/DeepSeek-V3.2",
        "deepseek-ai/DeepSeek-R1",
        "Qwen/Qwen3-235B-A22B-Instruct-2507",
        "moonshotai/Kimi-K2-Instruct",
        "openai/gpt-oss-120b"
    ),
    "Mistral" to listOf(
        "mistral-large-latest",
        "mistral-medium-latest",
        "mistral-small-latest",
        "codestral-latest",
        "devstral-small-latest"
    ),
    "Ollama" to listOf(
        "llama4",
        "gemma3",
        "qwen3",
        "deepseek-r1",
        "llama3.3",
        "phi4"
    )
)

private fun modelOptionsForProvider(provider: String): List<String> =
    (aiModelsByProvider[provider] ?: emptyList()) + customAIModel

private fun defaultModelForProvider(provider: String): String =
    aiModelsByProvider[provider]?.firstOrNull() ?: customAIModel

private const val otherGoalOption = "Other"
private val genderOptions = listOf("Male", "Female", "Non-binary", "Prefer not to say")
private val profileGoalOptions = listOf("Muscle Gain", "Fat Loss", "Strength", "Beginner Form", otherGoalOption)
private val frequencyOptions = (1..7).map { "$it days/week" }
private val workoutSplitOptions = listOf(
    "Full Body",
    "Upper Lower",
    "Push Pull Legs",
    "Bro Split",
    "Arnold Split",
    "Push Pull",
    "Antagonist Split",
    "Hybrid Split",
    "Custom"
)

private data class TargetMuscleGroup(
    val id: String,
    val title: String,
    val detail: String,
    val muscles: Set<String>,
    val isComposite: Boolean,
    val maleImageRes: Int,
    val femaleImageRes: Int
) {
    @DrawableRes
    fun imageRes(gender: String): Int =
        if (gender == "Female") femaleImageRes else maleImageRes
}

private object TargetMuscleImageSources {
    val maleChest = R.drawable.target_male_chest
    val maleBack = R.drawable.target_male_back
    val maleShoulders = R.drawable.target_male_shoulders
    val maleArms = R.drawable.target_male_arms
    val maleCore = R.drawable.target_male_core
    val maleLegs = R.drawable.target_male_legs
    val femaleChest = R.drawable.target_female_chest
    val femaleBack = R.drawable.target_female_back
    val femaleShoulders = R.drawable.target_female_shoulders
    val femaleArms = R.drawable.target_female_arms
    val femaleCore = R.drawable.target_female_core
    val femaleLegs = R.drawable.target_female_legs
}

private val targetMuscleGroups = listOf(
    TargetMuscleGroup("chest", "Chest", "Pecs", setOf("Chest"), false, TargetMuscleImageSources.maleChest, TargetMuscleImageSources.femaleChest),
    TargetMuscleGroup("back", "Back", "Lats, middle back, lower back, traps", setOf("Lats", "Middle Back", "Lower Back", "Traps"), true, TargetMuscleImageSources.maleBack, TargetMuscleImageSources.femaleBack),
    TargetMuscleGroup("shoulders", "Shoulders", "Delts and traps", setOf("Shoulders", "Traps"), true, TargetMuscleImageSources.maleShoulders, TargetMuscleImageSources.femaleShoulders),
    TargetMuscleGroup("arms", "Arms", "Biceps, triceps, forearms", setOf("Biceps", "Triceps", "Forearms"), true, TargetMuscleImageSources.maleArms, TargetMuscleImageSources.femaleArms),
    TargetMuscleGroup("core", "Abs / Core", "Abdominals", setOf("Abdominals"), false, TargetMuscleImageSources.maleCore, TargetMuscleImageSources.femaleCore),
    TargetMuscleGroup("legs", "Legs", "Quads, hamstrings, glutes, calves, hips", setOf("Quadriceps", "Hamstrings", "Glutes", "Calves", "Abductors", "Adductors"), true, TargetMuscleImageSources.maleLegs, TargetMuscleImageSources.femaleLegs),
    TargetMuscleGroup("biceps", "Biceps", "Front upper arm", setOf("Biceps"), false, TargetMuscleImageSources.maleArms, TargetMuscleImageSources.femaleArms),
    TargetMuscleGroup("triceps", "Triceps", "Back upper arm", setOf("Triceps"), false, TargetMuscleImageSources.maleArms, TargetMuscleImageSources.femaleArms),
    TargetMuscleGroup("forearms", "Forearms", "Grip and lower arm", setOf("Forearms"), false, TargetMuscleImageSources.maleArms, TargetMuscleImageSources.femaleArms),
    TargetMuscleGroup("lats", "Lats", "Width-focused back", setOf("Lats"), false, TargetMuscleImageSources.maleBack, TargetMuscleImageSources.femaleBack),
    TargetMuscleGroup("middle-back", "Middle Back", "Rows and upper-back thickness", setOf("Middle Back"), false, TargetMuscleImageSources.maleBack, TargetMuscleImageSources.femaleBack),
    TargetMuscleGroup("lower-back", "Lower Back", "Spinal erectors", setOf("Lower Back"), false, TargetMuscleImageSources.maleBack, TargetMuscleImageSources.femaleBack),
    TargetMuscleGroup("traps", "Traps", "Upper back and neck line", setOf("Traps"), false, TargetMuscleImageSources.maleShoulders, TargetMuscleImageSources.femaleShoulders),
    TargetMuscleGroup("quads", "Quads", "Quadriceps", setOf("Quadriceps"), false, TargetMuscleImageSources.maleLegs, TargetMuscleImageSources.femaleLegs),
    TargetMuscleGroup("hamstrings", "Hamstrings", "Posterior thigh", setOf("Hamstrings"), false, TargetMuscleImageSources.maleLegs, TargetMuscleImageSources.femaleLegs),
    TargetMuscleGroup("glutes", "Glutes", "Hips and glutes", setOf("Glutes"), false, TargetMuscleImageSources.maleLegs, TargetMuscleImageSources.femaleLegs),
    TargetMuscleGroup("calves", "Calves", "Lower leg", setOf("Calves"), false, TargetMuscleImageSources.maleLegs, TargetMuscleImageSources.femaleLegs),
    TargetMuscleGroup("hips", "Hips", "Abductors, adductors", setOf("Abductors", "Adductors"), true, TargetMuscleImageSources.maleLegs, TargetMuscleImageSources.femaleLegs),
    TargetMuscleGroup("neck", "Neck", "Neck", setOf("Neck"), false, TargetMuscleImageSources.maleShoulders, TargetMuscleImageSources.femaleShoulders)
)

private val datasetPrimaryMuscleNames = listOf(
    "Abdominals",
    "Abductors",
    "Adductors",
    "Biceps",
    "Calves",
    "Chest",
    "Forearms",
    "Glutes",
    "Hamstrings",
    "Lats",
    "Lower Back",
    "Middle Back",
    "Neck",
    "Quadriceps",
    "Shoulders",
    "Traps",
    "Triceps"
)

private fun targetMuscleGroupsFor(allowedValues: List<String>): List<TargetMuscleGroup> {
    val allowed = allowedValues.toSet()
    return targetMuscleGroups.filter { group -> group.muscles.any { allowed.contains(it) } }
}

private fun normalizeTargetMuscleSelection(selection: Set<String>, allowedValues: List<String> = datasetPrimaryMuscleNames): Set<String> {
    val allowed = allowedValues.toSet()
    return selection.flatMap { value ->
        when {
            allowed.contains(value) -> listOf(value)
            else -> targetMuscleGroups
                .firstOrNull { it.title.equals(value, ignoreCase = true) || it.id.equals(value, ignoreCase = true) }
                ?.muscles
                .orEmpty()
        }
    }
        .filter { allowed.contains(it) }
        .toSet()
}

private fun toggleTargetMuscleGroup(
    selection: Set<String>,
    group: TargetMuscleGroup,
    allowedValues: List<String>
): Set<String> {
    val normalizedSelection = normalizeTargetMuscleSelection(selection, allowedValues)
    val groupMuscles = group.muscles.filter { allowedValues.contains(it) }.toSet()
    if (groupMuscles.isEmpty()) return normalizedSelection

    return if (normalizedSelection.containsAll(groupMuscles)) {
        val protectedMuscles = targetMuscleGroupsFor(allowedValues)
            .filter { it.id != group.id }
            .filter { normalizedSelection.containsAll(it.muscles.filter { muscle -> allowedValues.contains(muscle) }) }
            .flatMap { it.muscles }
            .toSet()

        normalizedSelection - (groupMuscles - protectedMuscles)
    } else {
        normalizedSelection + groupMuscles
    }
}

private fun selectedTargetMuscleGroups(selection: Set<String>, allowedValues: List<String>): List<TargetMuscleGroup> {
    val normalizedSelection = normalizeTargetMuscleSelection(selection, allowedValues)
    if (normalizedSelection.isEmpty()) return emptyList()

    val fullySelected = targetMuscleGroupsFor(allowedValues).filter { group ->
        normalizedSelection.containsAll(group.muscles.filter { allowedValues.contains(it) })
    }
    val compositeCoverage = fullySelected
        .filter { it.isComposite }
        .flatMap { it.muscles }
        .toSet()

    return fullySelected.filter { group ->
        group.isComposite || !compositeCoverage.containsAll(group.muscles)
    }
}

private fun targetMuscleSummary(selection: Set<String>, allowedValues: List<String>): String {
    val titles = selectedTargetMuscleGroups(selection, allowedValues).map { it.title }
    return when {
        titles.isEmpty() -> "None"
        titles.size <= 2 -> titles.joinToString(", ")
        else -> "${titles.size} selected"
    }
}

private data class WorkoutSplitMuscleGroup(val title: String, val muscles: Set<String>)

private fun splitMuscleGroupsFor(split: String): List<WorkoutSplitMuscleGroup> =
    when (split) {
        "Full Body" -> emptyList()
        "Upper Lower" -> listOf(
            WorkoutSplitMuscleGroup("Upper", setOf("Biceps", "Chest", "Forearms", "Lats", "Middle Back", "Neck", "Shoulders", "Traps", "Triceps")),
            WorkoutSplitMuscleGroup("Lower", setOf("Abductors", "Adductors", "Calves", "Glutes", "Hamstrings", "Lower Back", "Quadriceps")),
            WorkoutSplitMuscleGroup("Core", setOf("Abdominals"))
        )
        "Push Pull Legs" -> listOf(
            WorkoutSplitMuscleGroup("Push", setOf("Chest", "Shoulders", "Triceps")),
            WorkoutSplitMuscleGroup("Pull", setOf("Biceps", "Forearms", "Lats", "Middle Back", "Traps", "Neck")),
            WorkoutSplitMuscleGroup("Legs", setOf("Abductors", "Adductors", "Calves", "Glutes", "Hamstrings", "Lower Back", "Quadriceps")),
            WorkoutSplitMuscleGroup("Core", setOf("Abdominals"))
        )
        "Bro Split" -> listOf(
            WorkoutSplitMuscleGroup("Chest", setOf("Chest")),
            WorkoutSplitMuscleGroup("Back", setOf("Lats", "Middle Back", "Lower Back", "Traps")),
            WorkoutSplitMuscleGroup("Shoulders", setOf("Shoulders", "Traps")),
            WorkoutSplitMuscleGroup("Arms", setOf("Biceps", "Triceps", "Forearms")),
            WorkoutSplitMuscleGroup("Legs", setOf("Abductors", "Adductors", "Calves", "Glutes", "Hamstrings", "Quadriceps")),
            WorkoutSplitMuscleGroup("Core", setOf("Abdominals"))
        )
        "Arnold Split" -> listOf(
            WorkoutSplitMuscleGroup("Chest + Back", setOf("Chest", "Lats", "Middle Back", "Lower Back", "Traps")),
            WorkoutSplitMuscleGroup("Shoulders + Arms", setOf("Shoulders", "Biceps", "Triceps", "Forearms", "Neck")),
            WorkoutSplitMuscleGroup("Legs", setOf("Abductors", "Adductors", "Calves", "Glutes", "Hamstrings", "Quadriceps")),
            WorkoutSplitMuscleGroup("Core", setOf("Abdominals"))
        )
        "Push Pull" -> listOf(
            WorkoutSplitMuscleGroup("Push", setOf("Chest", "Shoulders", "Triceps", "Quadriceps", "Calves")),
            WorkoutSplitMuscleGroup("Pull", setOf("Biceps", "Forearms", "Lats", "Middle Back", "Traps", "Glutes", "Hamstrings", "Lower Back")),
            WorkoutSplitMuscleGroup("Accessory/Core", setOf("Abdominals", "Abductors", "Adductors", "Neck"))
        )
        "Antagonist Split" -> listOf(
            WorkoutSplitMuscleGroup("Chest + Back", setOf("Chest", "Lats", "Middle Back", "Lower Back", "Traps")),
            WorkoutSplitMuscleGroup("Biceps + Triceps", setOf("Biceps", "Triceps", "Forearms")),
            WorkoutSplitMuscleGroup("Quads + Hamstrings/Glutes", setOf("Quadriceps", "Hamstrings", "Glutes")),
            WorkoutSplitMuscleGroup("Shoulders + Lats/Traps", setOf("Shoulders", "Lats", "Traps")),
            WorkoutSplitMuscleGroup("Core/Accessory", setOf("Abdominals", "Abductors", "Adductors", "Calves", "Neck"))
        )
        "Hybrid Split" -> listOf(
            WorkoutSplitMuscleGroup("Strength/Compound", setOf("Chest", "Lats", "Middle Back", "Lower Back", "Glutes", "Hamstrings", "Quadriceps", "Shoulders", "Traps")),
            WorkoutSplitMuscleGroup("Accessory/Hypertrophy", setOf("Biceps", "Triceps", "Forearms", "Calves", "Abductors", "Adductors", "Abdominals", "Neck"))
        )
        else -> emptyList()
    }

private const val otherIssueOption = "Other"
private val issueOptions = listOf(
    DeltsOption("Low motivation", "Consistency risk.", Icons.Filled.Warning),
    DeltsOption("No equipment", "Gear limits.", Icons.Filled.Warning),
    DeltsOption("Knee pain", "Lower-body caution.", Icons.Filled.Warning),
    DeltsOption("Shoulder pain", "Pressing caution.", Icons.Filled.Warning),
    DeltsOption("Busy schedule", "Time pressure.", Icons.Filled.Warning),
    DeltsOption("Beginner form", "Technique focus.", Icons.Filled.Warning),
    DeltsOption(otherIssueOption, "Custom issue.", Icons.Filled.Warning)
)

private val sampleExerciseLibrary = listOf(
    ExerciseItem(name = "Barbell Bench Press", level = "Intermediate", imagePaths = emptyList(), rawEquipment = "Barbell", primaryMuscles = listOf("Chest")),
    ExerciseItem(name = "Incline Dumbbell Press", level = "Intermediate", imagePaths = emptyList(), rawEquipment = "Dumbbells", primaryMuscles = listOf("Chest")),
    ExerciseItem(name = "Cable Crossover", level = "Beginner", imagePaths = emptyList(), rawEquipment = "Cable Machine", primaryMuscles = listOf("Chest")),
    ExerciseItem(name = "Lat Pulldown", level = "Beginner", imagePaths = emptyList(), rawEquipment = "Cable Machine", primaryMuscles = listOf("Lats")),
    ExerciseItem(name = "One-Arm Dumbbell Row", level = "Intermediate", imagePaths = emptyList(), rawEquipment = "Dumbbells", primaryMuscles = listOf("Middle Back")),
    ExerciseItem(name = "Seated Cable Row", level = "Beginner", imagePaths = emptyList(), rawEquipment = "Cable Machine", primaryMuscles = listOf("Middle Back")),
    ExerciseItem(name = "Dumbbell Shoulder Press", level = "Intermediate", imagePaths = emptyList(), rawEquipment = "Dumbbells", primaryMuscles = listOf("Shoulders")),
    ExerciseItem(name = "Lateral Raise", level = "Beginner", imagePaths = emptyList(), rawEquipment = "Dumbbells", primaryMuscles = listOf("Shoulders")),
    ExerciseItem(name = "Back Squat", level = "Expert", imagePaths = emptyList(), rawEquipment = "Barbell", primaryMuscles = listOf("Quadriceps")),
    ExerciseItem(name = "Goblet Squat", level = "Beginner", imagePaths = emptyList(), rawEquipment = "Dumbbells", primaryMuscles = listOf("Quadriceps")),
    ExerciseItem(name = "Dumbbell Curl", level = "Beginner", imagePaths = emptyList(), rawEquipment = "Dumbbells", primaryMuscles = listOf("Biceps")),
    ExerciseItem(name = "Cable Triceps Pressdown", level = "Beginner", imagePaths = emptyList(), rawEquipment = "Cable Machine", primaryMuscles = listOf("Triceps")),
    ExerciseItem(name = "Plank", level = "Beginner", imagePaths = emptyList(), rawEquipment = "Bodyweight", primaryMuscles = listOf("Abdominals")),
    ExerciseItem(name = "Cable Woodchop", level = "Intermediate", imagePaths = emptyList(), rawEquipment = "Cable Machine", primaryMuscles = listOf("Abdominals"))
)

@Preview(showBackground = true)
@Composable
private fun DeltsAppPreview() {
    DeltsTheme {
        DeltsScreenBackground {
            StartScreen(
                profile = AndroidProfile(
                    name = "Athlete",
                    gender = "Male",
                    age = 24,
                    heightCm = 178.0,
                    weightKg = 75.0,
                    goalWeightKg = 75.0,
                    currentBodyFat = 18.0,
                    desiredBodyFat = 12.0,
                    experience = "Intermediate",
                    mainGoal = "Muscle Gain",
                    selectedGoals = setOf("Muscle Gain"),
                    extraGoals = "",
                    extraIssues = "",
                    frequency = 4,
                    workoutSplit = "Push Pull Legs",
                    customWorkoutSplit = "",
                    duration = 60,
                    availableEquipment = setOf("Dumbbells", "Bench", "Cable Machine"),
                    bodyFocus = setOf("Chest", "Shoulders"),
                    issues = emptySet()
                ),
                exerciseLibrary = sampleExerciseLibrary,
                padding = PaddingValues()
            )
        }
    }
}
