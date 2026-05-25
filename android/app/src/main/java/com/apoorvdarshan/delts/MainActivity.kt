package com.apoorvdarshan.delts

import android.content.SharedPreferences
import android.content.res.AssetManager
import android.graphics.BitmapFactory
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DirectionsRun
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
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
import java.util.Locale
import kotlinx.coroutines.delay
import org.json.JSONArray
import kotlin.math.roundToInt

private const val SETTINGS_NAME = "delts_settings"

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
    val keyStore = remember(settings) { GeminiKeyStore(settings) }
    val fallbackKeyStore = remember(settings) { GeminiKeyStore(settings, "ai_fallback_api_key") }
    val exerciseLibrary = remember(context) { loadFreeExerciseDB(context.assets) }

    fun updateProfile(updatedProfile: AndroidProfile) {
        profile = updatedProfile
        settings.saveProfile(updatedProfile)
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
                    padding = padding
                )
                DeltsTab.Workouts -> WorkoutsScreen(
                    exerciseLibrary = exerciseLibrary,
                    padding = padding
                )
                DeltsTab.Profile -> ProfileScreen(
                    profile = profile,
                    updateProfile = ::updateProfile,
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
    padding: PaddingValues
) {
    var selectedMuscle by rememberSaveable { mutableStateOf("Chest") }
    var selectedLevel by rememberSaveable { mutableStateOf("Intermediate") }
    var selectedGoal by rememberSaveable { mutableStateOf("Muscle Gain") }
    var selectedDuration by rememberSaveable { mutableStateOf(60) }
    var equipmentMode by rememberSaveable { mutableStateOf(defaultEquipmentMode(profile)) }
    var selectedEquipment by rememberSaveable { mutableStateOf(defaultEquipment(profile).toList()) }
    var generatedPlan by remember { mutableStateOf<List<ExercisePlan>>(emptyList()) }

    LaunchedEffect(profile.availableEquipment) {
        val defaultEquipment = defaultEquipment(profile)
        equipmentMode = defaultEquipmentMode(profile)
        selectedEquipment = defaultEquipment.toList()
        generatedPlan = emptyList()
    }

    val muscle = muscles.first { it.title == selectedMuscle }
    val equipmentCount = selectedEquipment.size
    val heroExercise = exerciseLibrary.firstOrNull { it.muscle == selectedMuscle && it.imagePaths.isNotEmpty() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 12.dp, bottom = 118.dp),
        verticalArrangement = Arrangement.spacedBy(28.dp)
    ) {
        ScreenHeader(
            eyebrow = "DELTS",
            title = "Start",
            subtitle = "$selectedMuscle - $selectedLevel - $equipmentCount ${if (equipmentCount == 1) "item" else "items"}"
        )

        StartHero(
            muscle = muscle,
            imagePaths = heroExercise?.imagePaths.orEmpty(),
            profile = profile,
            selectedLevel = selectedLevel,
            selectedDuration = selectedDuration,
            equipmentCount = equipmentCount
        )

        StartSection(
            index = "01",
            title = "Equipment",
            subtitle = "Use profile gear, pick from saved gear, or skip to bodyweight."
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                DeltsPillButton(
                    title = "Profile gear",
                    icon = Icons.Filled.FitnessCenter,
                    selected = equipmentMode == EquipmentMode.Profile,
                    modifier = Modifier.weight(1f)
                ) {
                    equipmentMode = EquipmentMode.Profile
                    selectedEquipment = profile.availableEquipment.ifEmpty { setOf("Dumbbells") }.toList()
                    generatedPlan = emptyList()
                }
                DeltsPillButton(
                    title = "Skip",
                    icon = Icons.Filled.DirectionsRun,
                    selected = equipmentMode == EquipmentMode.Bodyweight,
                    modifier = Modifier.weight(1f)
                ) {
                    equipmentMode = EquipmentMode.Bodyweight
                    selectedEquipment = listOf("Bodyweight")
                    generatedPlan = emptyList()
                }
            }

            if (profile.availableEquipment.isEmpty()) {
                Text(
                    text = "No saved equipment yet. Add it from Profile when you want machine-specific plans.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                DeltsChipGrid(
                    items = profile.availableEquipment.toList(),
                    selected = selectedEquipment.toSet(),
                    itemIcon = { equipmentOptions.firstOrNull { it.title == this }?.icon ?: Icons.Filled.FitnessCenter }
                ) { equipment ->
                    equipmentMode = EquipmentMode.Profile
                    selectedEquipment = toggleInList(selectedEquipment, equipment).ifEmpty { listOf("Bodyweight") }
                    generatedPlan = emptyList()
                }
            }
        }

        StartSection(
            index = "02",
            title = "Body Part",
            subtitle = "Pick what you are training now. The library previews move between exercise frames."
        ) {
            TwoColumnGrid(muscles) { option ->
                val preview = exerciseLibrary.firstOrNull { it.muscle == option.title && it.imagePaths.isNotEmpty() }
                MuscleCard(
                    option = option,
                    previewImagePaths = preview?.imagePaths.orEmpty(),
                    selected = selectedMuscle == option.title
                ) {
                    selectedMuscle = option.title
                    generatedPlan = emptyList()
                }
            }
        }

        StartSection(
            index = "03",
            title = "Level",
            subtitle = "Choose intensity, duration, and training bias."
        ) {
            HorizontalChipRail {
                levels.forEach { level ->
                    DeltsPillButton(
                        title = level,
                        icon = Icons.Filled.FlashOn,
                        selected = selectedLevel == level
                    ) {
                        selectedLevel = level
                        generatedPlan = emptyList()
                    }
                }
            }

            HorizontalChipRail {
                goals.forEach { goal ->
                    DeltsPillButton(
                        title = goal,
                        icon = Icons.Filled.Flag,
                        selected = selectedGoal == goal
                    ) {
                        selectedGoal = goal
                        generatedPlan = emptyList()
                    }
                }
            }

            HorizontalChipRail {
                durations.forEach { duration ->
                    DeltsPillButton(
                        title = "$duration min",
                        icon = Icons.Filled.Timer,
                        selected = selectedDuration == duration
                    ) {
                        selectedDuration = duration
                        generatedPlan = emptyList()
                    }
                }
            }
        }

        if (generatedPlan.isNotEmpty()) {
            StartSection(
                index = "04",
                title = "Workout",
                subtitle = "Review the session, then log sets, reps, weight, skips, and rest inside Active Workout."
            ) {
                generatedPlan.take(5).forEach { exercise ->
                    ExercisePlanRow(exercise = exercise)
                }
            }
        }

        Button(
            onClick = {
                generatedPlan = buildPlan(
                    muscle = selectedMuscle,
                    level = selectedLevel,
                    goal = selectedGoal,
                    duration = selectedDuration,
                    equipment = selectedEquipment,
                    exerciseLibrary = exerciseLibrary
                )
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp),
            shape = RoundedCornerShape(27.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = DeltsAccent,
                contentColor = DeltsOnAccent
            )
        ) {
            Icon(Icons.Filled.PlayArrow, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Show Workouts", fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun WorkoutsScreen(
    exerciseLibrary: List<ExerciseItem>,
    padding: PaddingValues
) {
    var selectedMode by rememberSaveable { mutableStateOf(WorkoutsMode.Library) }
    var selectedMuscle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedLevel by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedEquipment by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedRawEquipment by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedPrimaryMuscle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedSecondaryMuscle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedForce by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedMechanic by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedCategory by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedMedia by rememberSaveable { mutableStateOf(LibraryMediaFilter.All) }
    var selectedSort by rememberSaveable { mutableStateOf(LibrarySort.BodyPart) }
    var search by rememberSaveable { mutableStateOf("") }

    val levelOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.level }.distinctSorted() }
    val equipmentOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.equipment }.distinctSorted() }
    val rawEquipmentOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.rawEquipment }.distinctSorted() }
    val primaryMuscleOptions = remember(exerciseLibrary) { exerciseLibrary.flatMap { it.primaryMuscles }.distinctSorted() }
    val secondaryMuscleOptions = remember(exerciseLibrary) { exerciseLibrary.flatMap { it.secondaryMuscles }.distinctSorted() }
    val forceOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.force }.distinctSorted() }
    val mechanicOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.mechanic }.distinctSorted() }
    val categoryOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.category }.distinctSorted() }

    val hasActiveFilters =
        selectedMuscle != null ||
            selectedLevel != null ||
            selectedEquipment != null ||
            selectedRawEquipment != null ||
            selectedPrimaryMuscle != null ||
            selectedSecondaryMuscle != null ||
            selectedForce != null ||
            selectedMechanic != null ||
            selectedCategory != null ||
            selectedMedia != LibraryMediaFilter.All ||
            selectedSort != LibrarySort.BodyPart ||
            search.isNotBlank()

    fun resetLibraryFilters() {
        selectedMuscle = null
        selectedLevel = null
        selectedEquipment = null
        selectedRawEquipment = null
        selectedPrimaryMuscle = null
        selectedSecondaryMuscle = null
        selectedForce = null
        selectedMechanic = null
        selectedCategory = null
        selectedMedia = LibraryMediaFilter.All
        selectedSort = LibrarySort.BodyPart
        search = ""
    }

    val filteredExercises = remember(
        selectedMuscle,
        selectedLevel,
        selectedEquipment,
        selectedRawEquipment,
        selectedPrimaryMuscle,
        selectedSecondaryMuscle,
        selectedForce,
        selectedMechanic,
        selectedCategory,
        selectedMedia,
        selectedSort,
        search,
        exerciseLibrary
    ) {
        val query = search.trim().lowercase(Locale.US)
        exerciseLibrary
            .filter { item ->
                (selectedMuscle == null || item.muscle == selectedMuscle) &&
                    (selectedLevel == null || item.level == selectedLevel) &&
                    (selectedEquipment == null || item.equipment == selectedEquipment) &&
                    (selectedRawEquipment == null || item.rawEquipment == selectedRawEquipment) &&
                    (selectedPrimaryMuscle?.let { item.primaryMuscles.contains(it) } ?: true) &&
                    (selectedSecondaryMuscle?.let { item.secondaryMuscles.contains(it) } ?: true) &&
                    (selectedForce == null || item.force == selectedForce) &&
                    (selectedMechanic == null || item.mechanic == selectedMechanic) &&
                    (selectedCategory == null || item.category == selectedCategory) &&
                    selectedMedia.matches(item) &&
                    (query.isBlank() || item.searchableText().contains(query))
            }
            .sortedWith(selectedSort.comparator())
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
    ) {
        if (selectedMode == WorkoutsMode.Library) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .padding(top = 16.dp, bottom = 112.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp)
            ) {
                LibrarySummary(
                    count = filteredExercises.size,
                    totalCount = exerciseLibrary.size,
                    hasSelection = hasActiveFilters
                )

                WorkoutsModeTabs(selectedMode = selectedMode) { selectedMode = it }

                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    HorizontalChipRail {
                        LibrarySearchPill(search = search, onSearchChange = { search = it })
                        DeltsPillButton(
                            title = "All",
                            icon = Icons.Filled.FitnessCenter,
                            selected = selectedMuscle == null
                        ) {
                            selectedMuscle = null
                        }
                        muscles.forEach { option ->
                            DeltsPillButton(
                                title = option.title,
                                icon = option.icon,
                                selected = selectedMuscle == option.title
                            ) {
                                selectedMuscle = option.title
                            }
                        }
                    }

                    HorizontalChipRail {
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
                            title = "Equipment",
                            value = selectedEquipment ?: "All",
                            icon = Icons.Filled.FitnessCenter,
                            active = selectedEquipment != null,
                            options = equipmentOptions,
                            selectedOption = selectedEquipment,
                            allTitle = "All Equipment"
                        ) {
                            selectedEquipment = it
                            if (selectedEquipment != null) selectedRawEquipment = null
                        }
                        LibraryFilterMenu(
                            title = "Raw Gear",
                            value = selectedRawEquipment ?: "All",
                            icon = Icons.Filled.Build,
                            active = selectedRawEquipment != null,
                            options = rawEquipmentOptions,
                            selectedOption = selectedRawEquipment,
                            allTitle = "All Raw Gear"
                        ) {
                            selectedRawEquipment = it
                            if (selectedRawEquipment != null) selectedEquipment = null
                        }
                        LibraryFilterMenu(
                            title = "Sort",
                            value = selectedSort.title,
                            icon = Icons.Filled.List,
                            active = selectedSort != LibrarySort.BodyPart,
                            options = LibrarySort.entries.filter { it != LibrarySort.BodyPart }.map { it.title },
                            selectedOption = selectedSort.takeUnless { it == LibrarySort.BodyPart }?.title,
                            allTitle = LibrarySort.BodyPart.title
                        ) { selected ->
                            selectedSort = LibrarySort.entries.firstOrNull { it.title == selected } ?: LibrarySort.BodyPart
                        }
                    }

                    HorizontalChipRail {
                        LibraryFilterMenu(
                            title = "Category",
                            value = selectedCategory ?: "All",
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
                        LibraryFilterMenu(
                            title = "Media",
                            value = selectedMedia.title,
                            icon = Icons.Filled.Lock,
                            active = selectedMedia != LibraryMediaFilter.All,
                            options = LibraryMediaFilter.entries.filter { it != LibraryMediaFilter.All }.map { it.title },
                            selectedOption = selectedMedia.takeUnless { it == LibraryMediaFilter.All }?.title,
                            allTitle = LibraryMediaFilter.All.title
                        ) { selected ->
                            selectedMedia = LibraryMediaFilter.entries.firstOrNull { it.title == selected } ?: LibraryMediaFilter.All
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
                            if (selectedPrimaryMuscle != null) selectedSecondaryMuscle = null
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
                            if (selectedSecondaryMuscle != null) selectedPrimaryMuscle = null
                        }
                        if (hasActiveFilters) {
                            DeltsPillButton(
                                title = "Reset",
                                icon = Icons.Filled.Close,
                                selected = false
                            ) {
                                resetLibraryFilters()
                            }
                        }
                    }
                }

                if (!hasActiveFilters) {
                    Text(
                        text = "Select Body Part",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                    TwoColumnGrid(muscles) { option ->
                        val preview = exerciseLibrary.firstOrNull { it.muscle == option.title && it.imagePaths.isNotEmpty() }
                        MuscleCard(
                            option = option,
                            previewImagePaths = preview?.imagePaths.orEmpty(),
                            selected = false
                        ) {
                            selectedMuscle = option.title
                        }
                    }
                } else {
                    ResultsHeader(
                        title = "${filteredExercises.size} ${if (filteredExercises.size == 1) "exercise" else "exercises"}",
                        subtitle = selectedSort.title,
                        icon = Icons.Filled.Lock
                    )
                    filteredExercises.forEach { item ->
                        ExerciseLibraryRow(item = item)
                    }
                }
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .padding(top = 16.dp, bottom = 112.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp)
            ) {
                HistorySummary()

                WorkoutsModeTabs(selectedMode = selectedMode) { selectedMode = it }

                EmptyHistory()
            }
        }
    }
}

@Composable
private fun ProfileScreen(
    profile: AndroidProfile,
    updateProfile: (AndroidProfile) -> Unit,
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

    Column(
        modifier = Modifier
            .fillMaxSize()
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
                title = "Experience",
                icon = Icons.Filled.FlashOn,
                value = profile.experience,
                options = levels,
                selectedOption = profile.experience
            ) { updateProfile(profile.copy(experience = it)) }
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
            CompactMultiSelectRow(
                title = "Body parts",
                icon = Icons.Filled.FitnessCenter,
                items = bodyFocusOptions.map { it.title },
                selected = profile.bodyFocus,
            ) { item ->
                updateProfile(profile.copy(bodyFocus = toggleInSet(profile.bodyFocus, item)))
            }
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
                items = equipmentOptions.map { it.title },
                selected = profile.availableEquipment,
            ) { item ->
                updateProfile(profile.copy(availableEquipment = toggleInSet(profile.availableEquipment, item)))
            }
        }

    }
}

@Composable
private fun ScreenHeader(
    eyebrow: String,
    title: String,
    subtitle: String,
    compact: Boolean = false
) {
    Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Text(
            text = eyebrow,
            style = MaterialTheme.typography.labelLarge,
            color = DeltsAccent
        )
        Text(
            text = title,
            style = if (compact) MaterialTheme.typography.titleLarge else MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.ExtraBold,
            color = MaterialTheme.colorScheme.onBackground
        )
        Text(
            text = subtitle,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun StartHero(
    muscle: DeltsOption,
    imagePaths: List<String>,
    profile: AndroidProfile,
    selectedLevel: String,
    selectedDuration: Int,
    equipmentCount: Int
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
            fallbackIcon = muscle.icon,
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
            DeltsGlassLabel(title = "Guided workout", icon = Icons.Filled.FlashOn)

            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "${muscle.title} workout",
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = "${profile.displayName} - $selectedLevel - $selectedDuration min",
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.White.copy(alpha = 0.76f),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(24.dp))
                        .background(Color.Black.copy(alpha = 0.36f))
                        .padding(horizontal = 12.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    HeroMetric("Focus", muscle.title, muscle.icon, Modifier.weight(1f))
                    HeroMetric("Level", selectedLevel, Icons.Filled.FlashOn, Modifier.weight(1f))
                    HeroMetric("Gear", equipmentCount.toString(), Icons.Filled.FitnessCenter, Modifier.weight(1f))
                    HeroMetric("Time", selectedDuration.toString(), Icons.Filled.Timer, Modifier.weight(1f))
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
private fun StartSection(index: String, title: String, subtitle: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
            Text(
                text = index,
                style = MaterialTheme.typography.labelLarge,
                color = DeltsAccent
            )
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
private fun MuscleCard(
    option: DeltsOption,
    previewImagePaths: List<String>,
    selected: Boolean,
    onClick: () -> Unit
) {
    val shape = RoundedCornerShape(30.dp)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .clickable(onClick = onClick)
            .background(
                if (selected) DeltsAccent.copy(alpha = 0.10f) else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.34f)
            )
            .padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        ExerciseVisual(
            imagePaths = previewImagePaths,
            fallbackIcon = option.icon,
            modifier = Modifier
                .fillMaxWidth()
                .height(104.dp),
            cornerRadius = 22,
            iconSize = 48,
            contentScale = ContentScale.Crop
        )

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(option.icon, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(18.dp))
            Text(
                text = option.title,
                modifier = Modifier.weight(1f),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Icon(
                if (selected) Icons.Filled.Check else Icons.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = if (selected) DeltsAccent else MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(18.dp)
            )
        }
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
private fun WorkoutsModeTabs(
    selectedMode: WorkoutsMode,
    onSelect: (WorkoutsMode) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        WorkoutsMode.entries.forEach { mode ->
            DeltsPillButton(
                title = mode.title,
                icon = mode.icon,
                selected = selectedMode == mode,
                modifier = Modifier.weight(1f)
            ) {
                onSelect(mode)
            }
        }
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

@Composable
private fun LibrarySearchPill(
    search: String,
    onSearchChange: (String) -> Unit
) {
    Surface(
        modifier = Modifier
            .width(222.dp)
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
private fun <T> TwoColumnGrid(items: List<T>, content: @Composable (T) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        items.chunked(2).forEach { rowItems ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                rowItems.forEach { item ->
                    Box(modifier = Modifier.weight(1f)) {
                        content(item)
                    }
                }
                if (rowItems.size == 1) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun DeltsChipGrid(
    items: List<String>,
    selected: Set<String>,
    itemIcon: String.() -> ImageVector,
    onToggle: (String) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items.chunked(2).forEach { rowItems ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                rowItems.forEach { item ->
                    val isSelected = selected.contains(item)
                    Surface(
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp),
                        shape = RoundedCornerShape(24.dp),
                        color = if (isSelected) DeltsAccent.copy(alpha = 0.11f) else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.30f),
                        border = BorderStroke(
                            1.dp,
                            if (isSelected) DeltsAccent.copy(alpha = 0.42f) else MaterialTheme.colorScheme.outline.copy(alpha = 0.26f)
                        ),
                        onClick = { onToggle(item) }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(item.itemIcon(), contentDescription = null, tint = if (isSelected) DeltsAccent else DeltsSecondaryAccent, modifier = Modifier.size(17.dp))
                            Text(
                                text = item,
                                modifier = Modifier.weight(1f),
                                style = MaterialTheme.typography.labelLarge,
                                color = MaterialTheme.colorScheme.onBackground,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                            Icon(
                                if (isSelected) Icons.Filled.Check else Icons.Filled.Add,
                                contentDescription = null,
                                tint = if (isSelected) DeltsAccent else MaterialTheme.colorScheme.outline,
                                modifier = Modifier.size(17.dp)
                            )
                        }
                    }
                }
                if (rowItems.size == 1) {
                    Spacer(modifier = Modifier.weight(1f))
                }
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
            fallbackIcon = exercise.icon,
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
                text = "${exercise.sets} sets - ${exercise.reps} reps - ${exercise.restSeconds}s rest",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@Composable
private fun LibrarySummary(count: Int, totalCount: Int, hasSelection: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = if (hasSelection) "Exercise library" else "Choose a focus",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = if (hasSelection) "$count matching exercises" else "$totalCount offline exercises",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground
            )
            Text(
                text = if (hasSelection) "Build from filtered results" else "Select a body part to browse moving demos",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        DeltsGlassLabel("Motion demos", Icons.Filled.List, dark = false)
    }
}

@Composable
private fun HistorySummary() {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = "Workout history",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Completed sessions",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground
            )
            Text(
                text = "Review finished workouts when logs are available.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        DeltsGlassLabel("Local logs", Icons.Filled.History, dark = false)
    }
}

@Composable
private fun ResultsHeader(title: String, subtitle: String, icon: ImageVector) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(text = title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
            Text(text = subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun ExerciseLibraryRow(item: ExerciseItem) {
    var expanded by rememberSaveable(item.name) { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { expanded = !expanded }
            .padding(vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            ExerciseVisual(
                imagePaths = item.imagePaths,
                fallbackIcon = item.icon,
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
                    text = "${item.muscle} - ${item.equipment} - ${item.level}",
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
                if (expanded) Icons.Filled.Close else Icons.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.outline
            )
        }

        if (expanded) {
            ExerciseLibraryMetadata(item = item)
        }
    }
    HorizontalDivider(color = DividerDefaults.color.copy(alpha = 0.32f))
}

@Composable
private fun ExerciseLibraryMetadata(item: ExerciseItem) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.36f),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.22f))
    ) {
        Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            MetadataLine("Category", item.category)
            MetadataLine("Force", item.force)
            MetadataLine("Mechanic", item.mechanic)
            MetadataLine("Raw gear", item.rawEquipment)
            MetadataLine("Primary", item.primaryMuscles.ifEmpty { listOf("Unspecified") }.joinToString(", "))
            MetadataLine("Secondary", item.secondaryMuscles.ifEmpty { listOf("None") }.joinToString(", "))

            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Instructions",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onBackground
                )
                item.instructions.forEachIndexed { index, instruction ->
                    Row(horizontalArrangement = Arrangement.spacedBy(9.dp), verticalAlignment = Alignment.Top) {
                        Text(
                            text = "${index + 1}",
                            style = MaterialTheme.typography.labelLarge,
                            color = DeltsAccent
                        )
                        Text(
                            text = instruction,
                            modifier = Modifier.weight(1f),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MetadataLine(label: String, value: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
        Text(
            text = label,
            modifier = Modifier.width(86.dp),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onBackground
        )
        Text(
            text = value,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun EmptyHistory() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 20.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(Icons.Filled.List, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(42.dp))
        Spacer(modifier = Modifier.height(10.dp))
        Text("No completed workouts yet", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onBackground)
        Text(
            text = "Generate a plan, start it, then finish to create your first log.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
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
    measurementSystem: MeasurementSystem,
    kilograms: Double,
    onChange: (Double) -> Unit
) {
    val displayValue = if (measurementSystem == MeasurementSystem.Metric) kilograms else kilograms * 2.2046226218
    val range = if (measurementSystem == MeasurementSystem.Metric) 30..250 else 66..551
    val unit = if (measurementSystem == MeasurementSystem.Metric) "kg" else "lb"
    val parts = splitDecimal(displayValue, range)

    CompactMeasurementRow(
        title = "Weight",
        icon = Icons.Filled.FitnessCenter,
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
    muscle: String,
    level: String,
    goal: String,
    duration: Int,
    equipment: List<String>,
    exerciseLibrary: List<ExerciseItem>
): List<ExercisePlan> {
    val base = exerciseLibrary.filter { it.muscle == muscle }.ifEmpty { exerciseLibrary }
    val setCount = when {
        duration <= 30 -> 3
        duration >= 90 -> 5
        else -> 4
    }
    val repTarget = when (goal) {
        "Fat Loss" -> "12-15"
        "Strength" -> "4-6"
        else -> "8-10"
    }
    val rest = when (level) {
        "Beginner" -> 60
        "Advanced" -> 105
        else -> 90
    }

    return base.take(5).map { item ->
        ExercisePlan(
            name = item.name,
            sets = setCount,
            reps = repTarget,
            restSeconds = rest,
            icon = item.icon,
            imagePaths = item.imagePaths,
            equipment = equipment.firstOrNull() ?: item.equipment
        )
    }
}

private fun defaultEquipment(profile: AndroidProfile): Set<String> =
    profile.availableEquipment.ifEmpty { setOf("Bodyweight") }

private fun defaultEquipmentMode(profile: AndroidProfile): EquipmentMode =
    if (profile.availableEquipment.isEmpty()) EquipmentMode.Bodyweight else EquipmentMode.Profile

private fun toggleInSet(set: Set<String>, item: String): Set<String> =
    if (set.contains(item)) set - item else set + item

private fun toggleInList(list: List<String>, item: String): List<String> =
    if (list.contains(item)) list - item else list + item

private fun nearestDuration(value: Int): Int =
    durations.minBy { kotlin.math.abs(it - value) }

private val AndroidProfile.displayName: String
    get() = name.trim().ifEmpty { "Athlete" }

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

    return AndroidProfile(
        name = getString("profile_name", "Athlete").orEmpty(),
        age = getInt("profile_age", 24),
        heightCm = getDoubleCompat("profile_height_cm", 178.0),
        weightKg = getDoubleCompat("profile_weight_kg", getDoubleCompat("profile_weight", 75.0)),
        currentBodyFat = getDoubleCompat("profile_bodyfat_current", 18.0),
        desiredBodyFat = getDoubleCompat("profile_bodyfat_desired", 12.0),
        experience = getString("profile_experience", "Intermediate").orEmpty(),
        mainGoal = mainGoal,
        selectedGoals = selectedGoals,
        extraGoals = extraGoals,
        extraIssues = getString("profile_extra_issues", "").orEmpty(),
        frequency = getInt("profile_frequency", 4),
        workoutSplit = getString("profile_workout_split", "Push Pull Legs").orEmpty(),
        customWorkoutSplit = getString("profile_custom_workout_split", "").orEmpty(),
        duration = getInt("profile_duration", 60),
        availableEquipment = getStringSet("profile_equipment", setOf("Dumbbells", "Bench", "Cable Machine")) ?: emptySet(),
        bodyFocus = getStringSet("profile_focus", setOf("Chest", "Shoulders", "Back")) ?: emptySet(),
        issues = getStringSet("profile_issues", emptySet()) ?: emptySet()
    )
}

private fun SharedPreferences.saveProfile(profile: AndroidProfile) {
    edit()
        .putString("profile_name", profile.name)
        .putInt("profile_age", profile.age)
        .putString("profile_height_cm", formatOneDecimal(profile.heightCm))
        .putString("profile_weight_kg", formatOneDecimal(profile.weightKg))
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
        .putStringSet("profile_focus", profile.bodyFocus)
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
    Profile("Profile", Icons.Filled.Person)
}

private enum class MeasurementSystem(val title: String) {
    Metric("Metric"),
    Imperial("Imperial")
}

private enum class EquipmentMode {
    Profile,
    Bodyweight
}

private enum class WorkoutsMode(val title: String, val icon: ImageVector) {
    Library("Library", Icons.Filled.FitnessCenter),
    History("History", Icons.Filled.History)
}

private enum class LibrarySort(val title: String) {
    BodyPart("Body Part"),
    Name("Name"),
    Level("Level"),
    Equipment("Equipment"),
    Category("DB Category"),
    Force("Force"),
    Mechanic("Mechanic"),
    RawEquipment("Raw Gear"),
    Media("Media")
}

private enum class LibraryMediaFilter(val title: String) {
    All("All"),
    WithMedia("With Media"),
    NoMedia("No Media")
}

private data class AndroidProfile(
    val name: String,
    val age: Int,
    val heightCm: Double,
    val weightKg: Double,
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
    val muscle: String,
    val equipment: String,
    val level: String,
    val machineLabel: String,
    val icon: ImageVector,
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
    val sets: Int,
    val reps: String,
    val restSeconds: Int,
    val equipment: String,
    val icon: ImageVector,
    val imagePaths: List<String>
)

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
            val muscle = muscleGroupFor(primaryMuscles, secondaryMuscles, record.optString("category"))
            val equipment = equipmentFor(record.optString("equipment"), name)
            val icon = muscles.firstOrNull { it.title == muscle }?.icon ?: Icons.Filled.FitnessCenter
            val instructions = record.optJSONArray("instructions").stringList()

            add(
                ExerciseItem(
                    name = name,
                    muscle = muscle,
                    equipment = equipment,
                    level = experienceLevelFor(record.optString("level")),
                    machineLabel = equipmentFamilyFor(equipment),
                    icon = icon,
                    imagePaths = record.optJSONArray("images").stringList(),
                    force = metadataTitle(record.optString("force")),
                    mechanic = metadataTitle(record.optString("mechanic")),
                    category = metadataTitle(record.optString("category")),
                    rawEquipment = metadataTitle(record.optString("equipment")),
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

private fun LibraryMediaFilter.matches(item: ExerciseItem): Boolean =
    when (this) {
        LibraryMediaFilter.All -> true
        LibraryMediaFilter.WithMedia -> item.imagePaths.isNotEmpty()
        LibraryMediaFilter.NoMedia -> item.imagePaths.isEmpty()
    }

private fun LibrarySort.comparator(): Comparator<ExerciseItem> =
    when (this) {
        LibrarySort.BodyPart -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.muscle }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Name -> compareBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Level -> compareBy<ExerciseItem> { levelSortRank(it.level) }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Equipment -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.equipment }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Category -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.category }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Force -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.force }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Mechanic -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.mechanic }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.RawEquipment -> compareBy<ExerciseItem, String>(String.CASE_INSENSITIVE_ORDER) { it.rawEquipment }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
        LibrarySort.Media -> compareByDescending<ExerciseItem> { it.imagePaths.size }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name }
    }

private fun levelSortRank(level: String): Int =
    when (level) {
        "Beginner" -> 0
        "Intermediate" -> 1
        "Advanced" -> 2
        else -> 3
    }

private fun ExerciseItem.databaseSummary(): String {
    val summary = listOf(category, force, mechanic)
        .filter { it != "Unspecified" }
        .joinToString(" - ")
        .ifBlank { machineLabel }

    return if (imagePaths.size > 1) "$summary - ${imagePaths.size} media" else summary
}

private fun ExerciseItem.searchableText(): String =
    listOf(
        name,
        muscle,
        equipment,
        level,
        machineLabel,
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

private fun muscleGroupFor(primaryMuscles: List<String>, secondaryMuscles: List<String>, category: String): String {
    val joined = (primaryMuscles + secondaryMuscles).joinToString(" ").lowercase()

    return when {
        "chest" in joined -> "Chest"
        "lats" in joined || "back" in joined || "traps" in joined -> "Back"
        "quadriceps" in joined ||
            "hamstrings" in joined ||
            "calves" in joined ||
            "glutes" in joined ||
            "adductors" in joined ||
            "abductors" in joined -> "Legs"
        "shoulders" in joined -> "Shoulders"
        "biceps" in joined || "triceps" in joined || "forearms" in joined -> "Arms"
        "abdominals" in joined -> "Core"
        category.lowercase() in setOf("cardio", "plyometrics", "strongman", "olympic weightlifting") -> "Full Body"
        else -> "Full Body"
    }
}

private fun equipmentFor(rawEquipment: String, exerciseName: String): String {
    val equipment = rawEquipment.lowercase()
    val name = exerciseName.lowercase()

    return when {
        "treadmill" in name -> "Treadmill"
        "pull-up" in name || "pull up" in name || "chin-up" in name || "chin up" in name -> "Pull-Up Bar"
        "leg press" in name -> "Leg Press"
        "leg extension" in name -> "Leg Extension"
        "leg curl" in name -> "Leg Curl"
        "lat pulldown" in name || "pulldown" in name -> "Lat Pulldown"
        "chest press" in name -> "Chest Press"
        "shoulder press" in name && "machine" in equipment -> "Shoulder Press"
        "row" in name && "machine" in equipment -> "Row Machine"
        "dumbbell" in equipment || "kettlebell" in equipment -> "Dumbbells"
        "barbell" in equipment || "e-z" in equipment -> "Barbell"
        "cable" in equipment -> "Cable Machine"
        "machine" in equipment -> "Cable Machine"
        "bench" in name -> "Bench"
        else -> "Bodyweight"
    }
}

private fun experienceLevelFor(rawLevel: String): String =
    when (rawLevel.lowercase()) {
        "beginner" -> "Beginner"
        "expert", "advanced" -> "Advanced"
        else -> "Intermediate"
    }

private fun equipmentFamilyFor(equipment: String): String =
    when (equipment) {
        "Chest Press",
        "Shoulder Press",
        "Lat Pulldown",
        "Row Machine",
        "Leg Press",
        "Leg Extension",
        "Leg Curl",
        "Smith Machine",
        "Cable Machine",
        "Treadmill" -> "Machines"
        "Dumbbells",
        "Barbell",
        "Bench",
        "Pull-Up Bar" -> "Free Weights"
        else -> "Bodyweight"
    }

private val muscles = listOf(
    DeltsOption("Chest", "Press, fly, and finish controlled volume.", Icons.Filled.FitnessCenter),
    DeltsOption("Back", "Rows, pulls, and strong scapular control.", Icons.Filled.FitnessCenter),
    DeltsOption("Shoulders", "Delts, stability, and overhead strength.", Icons.Filled.FitnessCenter),
    DeltsOption("Legs", "Squat, hinge, and athletic lower-body work.", Icons.Filled.DirectionsRun),
    DeltsOption("Arms", "Biceps, triceps, and high-quality pump work.", Icons.Filled.FitnessCenter),
    DeltsOption("Core", "Bracing, rotation, and trunk endurance.", Icons.Filled.Favorite),
    DeltsOption("Full Body", "Carry, condition, and train the whole system.", Icons.Filled.DirectionsRun)
)

private val levels = listOf("Beginner", "Intermediate", "Advanced")
private val goals = listOf("Muscle Gain", "Fat Loss", "Strength", "Beginner Form")
private const val otherGoalOption = "Other"
private val profileGoalOptions = goals + otherGoalOption
private val frequencyOptions = (1..7).map { "$it days/week" }
private val workoutSplitOptions = listOf("Full Body", "Push Pull Legs", "Upper Lower", "Bro Split", "Custom")
private val durations = listOf(30, 45, 60, 90)
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

private val equipmentOptions = listOf(
    DeltsOption("Bodyweight", "No gear.", Icons.Filled.DirectionsRun),
    DeltsOption("Dumbbells", "Free weights.", Icons.Filled.FitnessCenter),
    DeltsOption("Barbell", "Heavy compounds.", Icons.Filled.FitnessCenter),
    DeltsOption("Cable Machine", "Constant tension.", Icons.Filled.Build),
    DeltsOption("Bench", "Pressing support.", Icons.Filled.FitnessCenter),
    DeltsOption("Resistance Bands", "Portable tension.", Icons.Filled.Build)
)

private val bodyFocusOptions = listOf(
    DeltsOption("Chest", "Upper body push.", Icons.Filled.FitnessCenter),
    DeltsOption("Back", "Pulling strength.", Icons.Filled.FitnessCenter),
    DeltsOption("Shoulders", "Delts.", Icons.Filled.FitnessCenter),
    DeltsOption("Legs", "Lower body.", Icons.Filled.DirectionsRun),
    DeltsOption("Arms", "Arm work.", Icons.Filled.FitnessCenter),
    DeltsOption("Core", "Trunk.", Icons.Filled.Favorite)
)

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
    ExerciseItem("Barbell Bench Press", "Chest", "Barbell", "Intermediate", "Offline media", Icons.Filled.FitnessCenter, emptyList()),
    ExerciseItem("Incline Dumbbell Press", "Chest", "Dumbbells", "Intermediate", "Offline media", Icons.Filled.FitnessCenter, emptyList()),
    ExerciseItem("Cable Crossover", "Chest", "Cable Machine", "Beginner", "Offline media", Icons.Filled.Build, emptyList()),
    ExerciseItem("Lat Pulldown", "Back", "Cable Machine", "Beginner", "Offline media", Icons.Filled.FitnessCenter, emptyList()),
    ExerciseItem("One-Arm Dumbbell Row", "Back", "Dumbbells", "Intermediate", "Offline media", Icons.Filled.FitnessCenter, emptyList()),
    ExerciseItem("Seated Cable Row", "Back", "Cable Machine", "Beginner", "Offline media", Icons.Filled.Build, emptyList()),
    ExerciseItem("Dumbbell Shoulder Press", "Shoulders", "Dumbbells", "Intermediate", "Offline media", Icons.Filled.FitnessCenter, emptyList()),
    ExerciseItem("Lateral Raise", "Shoulders", "Dumbbells", "Beginner", "Offline media", Icons.Filled.FitnessCenter, emptyList()),
    ExerciseItem("Back Squat", "Legs", "Barbell", "Advanced", "Offline media", Icons.Filled.DirectionsRun, emptyList()),
    ExerciseItem("Goblet Squat", "Legs", "Dumbbells", "Beginner", "Offline media", Icons.Filled.DirectionsRun, emptyList()),
    ExerciseItem("Dumbbell Curl", "Arms", "Dumbbells", "Beginner", "Offline media", Icons.Filled.FitnessCenter, emptyList()),
    ExerciseItem("Cable Triceps Pressdown", "Arms", "Cable Machine", "Beginner", "Offline media", Icons.Filled.Build, emptyList()),
    ExerciseItem("Plank", "Core", "Bodyweight", "Beginner", "Offline media", Icons.Filled.Favorite, emptyList()),
    ExerciseItem("Cable Woodchop", "Core", "Cable Machine", "Intermediate", "Offline media", Icons.Filled.Build, emptyList())
)

@Preview(showBackground = true)
@Composable
private fun DeltsAppPreview() {
    DeltsTheme {
        DeltsScreenBackground {
            StartScreen(
                profile = AndroidProfile(
                    name = "Athlete",
                    age = 24,
                    heightCm = 178.0,
                    weightKg = 75.0,
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
