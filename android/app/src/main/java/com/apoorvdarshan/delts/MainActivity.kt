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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.apoorvdarshan.delts.ui.theme.DeltsAccent
import com.apoorvdarshan.delts.ui.theme.DeltsOnAccent
import com.apoorvdarshan.delts.ui.theme.DeltsSecondaryAccent
import com.apoorvdarshan.delts.ui.theme.DeltsTheme
import com.apoorvdarshan.delts.ui.theme.DeltsWarning
import kotlinx.coroutines.delay
import org.json.JSONArray

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
    val keyStore = remember(settings) { GeminiKeyStore(settings) }
    val exerciseLibrary = remember(context) { loadFreeExerciseDB(context.assets) }

    fun updateProfile(updatedProfile: AndroidProfile) {
        profile = updatedProfile
        settings.saveProfile(updatedProfile)
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
                    keyStore = keyStore,
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
    var search by rememberSaveable { mutableStateOf("") }

    val filteredExercises = remember(selectedMuscle, search) {
        exerciseLibrary.filter { item ->
            (selectedMuscle == null || item.muscle == selectedMuscle) &&
                (search.isBlank() || item.name.contains(search, ignoreCase = true) || item.equipment.contains(search, ignoreCase = true))
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.72f))
                .padding(horizontal = 20.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            ScreenHeader(
                eyebrow = "LIBRARY",
                title = "Workouts",
                subtitle = if (selectedMode == WorkoutsMode.Library) "Pick a focus, preview motion, build a session." else "Review completed sessions and logged sets.",
                compact = true
            )

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                WorkoutsMode.entries.forEach { mode ->
                    DeltsPillButton(
                        title = mode.title,
                        icon = mode.icon,
                        selected = selectedMode == mode,
                        modifier = Modifier.weight(1f)
                    ) {
                        selectedMode = mode
                    }
                }
            }
        }

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
                    hasSelection = selectedMuscle != null || search.isNotBlank()
                )

                OutlinedTextField(
                    value = search,
                    onValueChange = { search = it },
                    modifier = Modifier.fillMaxWidth(),
                    leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                    label = { Text("Search exercises") },
                    singleLine = true,
                    shape = RoundedCornerShape(18.dp)
                )

                HorizontalChipRail {
                    muscles.forEach { muscle ->
                        DeltsPillButton(
                            title = muscle.title,
                            icon = muscle.icon,
                            selected = selectedMuscle == muscle.title
                        ) {
                            selectedMuscle = if (selectedMuscle == muscle.title) null else muscle.title
                        }
                    }
                }

                if (selectedMuscle == null && search.isBlank()) {
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
                        subtitle = "Offline media",
                        icon = Icons.Filled.Lock
                    )
                    filteredExercises.forEach { item ->
                        ExerciseLibraryRow(item = item)
                    }
                }
            }
        } else {
            EmptyHistory()
        }
    }
}

@Composable
private fun ProfileScreen(
    profile: AndroidProfile,
    updateProfile: (AndroidProfile) -> Unit,
    keyStore: GeminiKeyStore,
    padding: PaddingValues
) {
    var apiKey by remember { mutableStateOf(keyStore.load()) }
    var hasSavedKey by remember { mutableStateOf(keyStore.hasKey()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(padding)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 12.dp, bottom = 112.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        ScreenHeader(
            eyebrow = "SETUP",
            title = "Profile",
            subtitle = "Training defaults and saved equipment."
        )

        ProfileHero(profile = profile)

        ProfileSection(
            title = "Body Profile",
            subtitle = "Used to shape plans and recommendations.",
            icon = Icons.Filled.Person
        ) {
            OutlinedTextField(
                value = profile.name,
                onValueChange = { updateProfile(profile.copy(name = it)) },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Name") },
                singleLine = true,
                shape = RoundedCornerShape(18.dp)
            )
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                NumberStepper(
                    title = "Age",
                    value = profile.age,
                    suffix = "",
                    modifier = Modifier.weight(1f)
                ) { updateProfile(profile.copy(age = it.coerceIn(13, 90))) }
                NumberStepper(
                    title = "Weight",
                    value = profile.weightKg,
                    suffix = "kg",
                    modifier = Modifier.weight(1f)
                ) { updateProfile(profile.copy(weightKg = it.coerceIn(30, 250))) }
            }
        }

        ProfileSection(
            title = "Goals",
            subtitle = "Set the training bias before plans are generated.",
            icon = Icons.Filled.Flag
        ) {
            HorizontalChipRail {
                levels.forEach { level ->
                    DeltsPillButton(
                        title = level,
                        icon = Icons.Filled.FlashOn,
                        selected = profile.experience == level
                    ) {
                        updateProfile(profile.copy(experience = level))
                    }
                }
            }
            HorizontalChipRail {
                goals.forEach { goal ->
                    DeltsPillButton(
                        title = goal,
                        icon = Icons.Filled.Flag,
                        selected = profile.mainGoal == goal
                    ) {
                        updateProfile(profile.copy(mainGoal = goal))
                    }
                }
            }
        }

        ProfileSection(
            title = "AI Settings",
            subtitle = "Gemini BYOK stays on this device.",
            icon = Icons.Filled.VpnKey,
            badge = if (hasSavedKey) "Ready" else "Local"
        ) {
            GeminiKeyCard(
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
        }

        ProfileSection(
            title = "Body Parts To Build",
            subtitle = "Choose the areas your workouts should emphasize.",
            icon = Icons.Filled.FitnessCenter,
            badge = profile.bodyFocus.size.toString()
        ) {
            DeltsChipGrid(
                items = bodyFocusOptions.map { it.title },
                selected = profile.bodyFocus,
                itemIcon = { bodyFocusOptions.firstOrNull { it.title == this }?.icon ?: Icons.Filled.FitnessCenter }
            ) { item ->
                updateProfile(profile.copy(bodyFocus = toggleInSet(profile.bodyFocus, item)))
            }
        }

        ProfileSection(
            title = "Schedule",
            subtitle = "Tune how training fits into the week.",
            icon = Icons.Filled.CalendarToday
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                NumberStepper(
                    title = "Weekly",
                    value = profile.frequency,
                    suffix = "x",
                    modifier = Modifier.weight(1f)
                ) { updateProfile(profile.copy(frequency = it.coerceIn(1, 7))) }
                NumberStepper(
                    title = "Duration",
                    value = profile.duration,
                    suffix = "min",
                    modifier = Modifier.weight(1f)
                ) { updateProfile(profile.copy(duration = nearestDuration(it))) }
            }
        }

        ProfileSection(
            title = "Equipment Library",
            subtitle = "Select gear here only. Start uses this saved library.",
            icon = Icons.Filled.FitnessCenter,
            badge = profile.availableEquipment.size.toString()
        ) {
            DeltsChipGrid(
                items = equipmentOptions.map { it.title },
                selected = profile.availableEquipment,
                itemIcon = { equipmentOptions.firstOrNull { it.title == this }?.icon ?: Icons.Filled.FitnessCenter }
            ) { item ->
                updateProfile(profile.copy(availableEquipment = toggleInSet(profile.availableEquipment, item)))
            }
        }

        ProfileSection(
            title = "Friction Points",
            subtitle = "Flag what usually gets in the way.",
            icon = Icons.Filled.Warning,
            badge = profile.issues.size.toString()
        ) {
            DeltsChipGrid(
                items = issueOptions.map { it.title },
                selected = profile.issues,
                itemIcon = { Icons.Filled.Warning }
            ) { item ->
                updateProfile(profile.copy(issues = toggleInSet(profile.issues, item)))
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
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 10.dp),
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
                text = item.machineLabel,
                style = MaterialTheme.typography.labelLarge,
                color = DeltsSecondaryAccent,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        Icon(Icons.Filled.KeyboardArrowRight, contentDescription = null, tint = MaterialTheme.colorScheme.outline)
    }
    HorizontalDivider(color = DividerDefaults.color.copy(alpha = 0.32f))
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
private fun ProfileHero(profile: AndroidProfile) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Box(
                modifier = Modifier
                    .size(46.dp)
                    .clip(CircleShape)
                    .background(DeltsAccent.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Filled.Person, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(30.dp))
            }

            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Text(
                    text = profile.displayName,
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = "${profile.experience} - ${profile.mainGoal}",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            DeltsGlassLabel("Local", Icons.Filled.Lock, dark = false)
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ProfileMetric("Weekly", "${profile.frequency}x", Icons.Filled.CalendarToday, Modifier.weight(1f))
            ProfileMetric("Duration", "${profile.duration} min", Icons.Filled.Timer, Modifier.weight(1f))
            ProfileMetric("Gear", profile.availableEquipment.size.toString(), Icons.Filled.FitnessCenter, Modifier.weight(1f))
            ProfileMetric("Focus", profile.bodyFocus.size.toString(), Icons.Filled.Flag, Modifier.weight(1f))
        }
    }
}

@Composable
private fun ProfileMetric(title: String, value: String, icon: ImageVector, modifier: Modifier = Modifier) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(15.dp))
        Column {
            Text(text = value, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onBackground, maxLines = 1)
            Text(text = title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
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
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.34f))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
            Icon(icon, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(28.dp))
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(text = title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
                Text(text = subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (badge != null) {
                Text(
                    text = badge,
                    style = MaterialTheme.typography.labelLarge,
                    color = DeltsAccent,
                    modifier = Modifier
                        .clip(RoundedCornerShape(14.dp))
                        .background(DeltsAccent.copy(alpha = 0.11f))
                        .padding(horizontal = 10.dp, vertical = 5.dp)
                )
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp), content = content)
    }
}

@Composable
private fun GeminiKeyCard(
    apiKey: String,
    hasSavedKey: Boolean,
    onApiKeyChange: (String) -> Unit,
    save: () -> Unit,
    clear: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(
                imageVector = if (hasSavedKey) Icons.Filled.Check else Icons.Filled.FlashOn,
                contentDescription = null,
                tint = if (hasSavedKey) DeltsAccent else DeltsWarning,
                modifier = Modifier.size(30.dp)
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("Gemini Key", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
                Text(
                    text = if (hasSavedKey) "Saved on device" else "Offline planner",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        OutlinedTextField(
            value = apiKey,
            onValueChange = onApiKeyChange,
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Paste API key") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            shape = RoundedCornerShape(14.dp)
        )

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            OutlinedButton(
                onClick = clear,
                modifier = Modifier
                    .weight(1f)
                    .height(42.dp),
                shape = RoundedCornerShape(14.dp)
            ) {
                Text("Clear", fontWeight = FontWeight.Bold)
            }
            Button(
                onClick = save,
                modifier = Modifier
                    .weight(1f)
                    .height(42.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = DeltsAccent, contentColor = DeltsOnAccent)
            ) {
                Text("Save Key", fontWeight = FontWeight.Bold)
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
            .background(
                Brush.linearGradient(
                    listOf(
                        MaterialTheme.colorScheme.background,
                        DeltsAccent.copy(alpha = 0.09f),
                        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.22f),
                        DeltsSecondaryAccent.copy(alpha = 0.06f),
                        MaterialTheme.colorScheme.background
                    )
                )
            )
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

private fun SharedPreferences.loadProfile(): AndroidProfile =
    AndroidProfile(
        name = getString("profile_name", "Athlete").orEmpty(),
        age = getInt("profile_age", 24),
        weightKg = getInt("profile_weight", 75),
        experience = getString("profile_experience", "Intermediate").orEmpty(),
        mainGoal = getString("profile_goal", "Muscle Gain").orEmpty(),
        frequency = getInt("profile_frequency", 4),
        duration = getInt("profile_duration", 60),
        availableEquipment = getStringSet("profile_equipment", setOf("Dumbbells", "Bench", "Cable Machine")) ?: emptySet(),
        bodyFocus = getStringSet("profile_focus", setOf("Chest", "Shoulders", "Back")) ?: emptySet(),
        issues = getStringSet("profile_issues", emptySet()) ?: emptySet()
    )

private fun SharedPreferences.saveProfile(profile: AndroidProfile) {
    edit()
        .putString("profile_name", profile.name)
        .putInt("profile_age", profile.age)
        .putInt("profile_weight", profile.weightKg)
        .putString("profile_experience", profile.experience)
        .putString("profile_goal", profile.mainGoal)
        .putInt("profile_frequency", profile.frequency)
        .putInt("profile_duration", profile.duration)
        .putStringSet("profile_equipment", profile.availableEquipment)
        .putStringSet("profile_focus", profile.bodyFocus)
        .putStringSet("profile_issues", profile.issues)
        .apply()
}

private enum class DeltsTab(val title: String, val icon: ImageVector) {
    Start("Start", Icons.Filled.PlayArrow),
    Workouts("Workouts", Icons.Filled.List),
    Profile("Profile", Icons.Filled.Person)
}

private enum class EquipmentMode {
    Profile,
    Bodyweight
}

private enum class WorkoutsMode(val title: String, val icon: ImageVector) {
    Library("Library", Icons.Filled.FitnessCenter),
    History("History", Icons.Filled.History)
}

private data class AndroidProfile(
    val name: String,
    val age: Int,
    val weightKg: Int,
    val experience: String,
    val mainGoal: String,
    val frequency: Int,
    val duration: Int,
    val availableEquipment: Set<String>,
    val bodyFocus: Set<String>,
    val issues: Set<String>
)

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
    val imagePaths: List<String>
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

            add(
                ExerciseItem(
                    name = name,
                    muscle = muscle,
                    equipment = equipment,
                    level = experienceLevelFor(record.optString("level")),
                    machineLabel = equipmentFamilyFor(equipment),
                    icon = icon,
                    imagePaths = record.optJSONArray("images").stringList()
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
private val durations = listOf(30, 45, 60, 90)

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

private val issueOptions = listOf(
    DeltsOption("Low motivation", "Consistency risk.", Icons.Filled.Warning),
    DeltsOption("No equipment", "Gear limits.", Icons.Filled.Warning),
    DeltsOption("Knee pain", "Lower-body caution.", Icons.Filled.Warning),
    DeltsOption("Shoulder pain", "Pressing caution.", Icons.Filled.Warning),
    DeltsOption("Busy schedule", "Time pressure.", Icons.Filled.Warning),
    DeltsOption("Beginner form", "Technique focus.", Icons.Filled.Warning)
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
                    weightKg = 75,
                    experience = "Intermediate",
                    mainGoal = "Muscle Gain",
                    frequency = 4,
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
