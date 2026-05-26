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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Search
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
    var datasetPreferences by remember { mutableStateOf(settings.loadDatasetPreferences()) }
    val exerciseLibrary = remember(context) { loadFreeExerciseDB(context.assets) }

    fun updateDatasetPreferences(updatedPreferences: DatasetPreferences) {
        datasetPreferences = updatedPreferences
        settings.saveDatasetPreferences(updatedPreferences)
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
                    exerciseLibrary = exerciseLibrary,
                    padding = padding
                )
                DeltsTab.Workouts -> WorkoutsScreen(
                    exerciseLibrary = exerciseLibrary,
                    padding = padding
                )
                DeltsTab.Profile -> ProfileScreen(
                    datasetPreferences = datasetPreferences,
                    updateDatasetPreferences = ::updateDatasetPreferences,
                    exerciseLibrary = exerciseLibrary,
                    padding = padding
                )
            }
        }
    }
}

@Composable
private fun StartScreen(
    exerciseLibrary: List<ExerciseItem>,
    padding: PaddingValues
) {
    var selectedPrimaryMuscle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedRawEquipment by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedLevel by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedCategory by rememberSaveable { mutableStateOf<String?>(null) }

    val primaryMuscleOptions = remember(exerciseLibrary) { exerciseLibrary.flatMap { it.primaryMuscles }.distinctSorted() }
    val rawEquipmentOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.rawEquipment }.distinctSorted() }
    val levelOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.level }.distinctSortedLevels() }
    val categoryOptions = remember(exerciseLibrary) { exerciseLibrary.map { it.category }.distinctSorted() }

    val matchingItems = remember(
        selectedPrimaryMuscle,
        selectedRawEquipment,
        selectedLevel,
        selectedCategory,
        exerciseLibrary
    ) {
        exerciseLibrary.filter { item ->
            (selectedPrimaryMuscle?.let { item.primaryMuscles.contains(it) } ?: true) &&
                (selectedRawEquipment == null || item.rawEquipment == selectedRawEquipment) &&
                (selectedLevel == null || item.level == selectedLevel) &&
                (selectedCategory == null || item.category == selectedCategory)
        }
    }

    val heroExercise = matchingItems.firstOrNull { it.imagePaths.isNotEmpty() } ?: matchingItems.firstOrNull() ?: exerciseLibrary.firstOrNull()
    val headerSubtitle = listOf(
        selectedPrimaryMuscle ?: "All primary",
        selectedRawEquipment ?: "All equipment",
        selectedLevel ?: "All levels"
    ).joinToString(" - ")

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
            subtitle = headerSubtitle
        )

        DatasetStartHero(
            item = heroExercise,
            imagePaths = heroExercise?.imagePaths.orEmpty(),
            fallbackIcon = Icons.Filled.FitnessCenter
        )

        StartSection(
            index = "01",
            title = "Primary",
            subtitle = "Choose from the dataset primaryMuscles field."
        ) {
            HorizontalChipRail {
                DeltsPillButton(
                    title = "All",
                    icon = Icons.Filled.FitnessCenter,
                    selected = selectedPrimaryMuscle == null
                ) {
                    selectedPrimaryMuscle = null
                }
                primaryMuscleOptions.forEach { muscle ->
                    DeltsPillButton(
                        title = muscle,
                        icon = Icons.Filled.FitnessCenter,
                        selected = selectedPrimaryMuscle == muscle
                    ) {
                        selectedPrimaryMuscle = muscle
                    }
                }
            }
        }

        StartSection(
            index = "02",
            title = "Equipment",
            subtitle = "Choose from the dataset equipment field."
        ) {
            HorizontalChipRail {
                DeltsPillButton(
                    title = "All",
                    icon = Icons.Filled.FitnessCenter,
                    selected = selectedRawEquipment == null
                ) {
                    selectedRawEquipment = null
                }
                rawEquipmentOptions.forEach { equipment ->
                    DeltsPillButton(
                        title = equipment,
                        icon = Icons.Filled.FitnessCenter,
                        selected = selectedRawEquipment == equipment
                    ) {
                        selectedRawEquipment = equipment
                    }
                }
            }
        }

        StartSection(
            index = "03",
            title = "Dataset",
            subtitle = "Filter by raw level and category."
        ) {
            HorizontalChipRail {
                DeltsPillButton(
                    title = "All levels",
                    icon = Icons.Filled.FlashOn,
                    selected = selectedLevel == null
                ) {
                    selectedLevel = null
                }
                levelOptions.forEach { level ->
                    DeltsPillButton(
                        title = level,
                        icon = Icons.Filled.FlashOn,
                        selected = selectedLevel == level
                    ) {
                        selectedLevel = level
                    }
                }
            }

            HorizontalChipRail {
                DeltsPillButton(
                    title = "All categories",
                    icon = Icons.Filled.List,
                    selected = selectedCategory == null
                ) {
                    selectedCategory = null
                }
                categoryOptions.forEach { category ->
                    DeltsPillButton(
                        title = category,
                        icon = Icons.Filled.List,
                        selected = selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }

        StartSection(
            index = "04",
            title = "Exercises",
            subtitle = "${matchingItems.size} matching dataset ${if (matchingItems.size == 1) "record" else "records"}."
        ) {
            matchingItems.take(5).forEach { exercise ->
                StartExerciseRow(exercise = exercise)
            }
        }
    }
}

@Composable
private fun WorkoutsScreen(
    exerciseLibrary: List<ExerciseItem>,
    padding: PaddingValues
) {
    var selectedLevel by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedRawEquipment by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedPrimaryMuscle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedSecondaryMuscle by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedForce by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedMechanic by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedCategory by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedSort by rememberSaveable { mutableStateOf(LibrarySort.Name) }
    var search by rememberSaveable { mutableStateOf("") }

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

    val hasActiveFilters =
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

    val filteredExercises = remember(
        selectedLevel,
        selectedRawEquipment,
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
            ExerciseLibraryRow(item = item)
        }
    }
}

@Composable
private fun ProfileScreen(
    datasetPreferences: DatasetPreferences,
    updateDatasetPreferences: (DatasetPreferences) -> Unit,
    exerciseLibrary: List<ExerciseItem>,
    padding: PaddingValues
) {
    val datasetLevels = remember(exerciseLibrary) { exerciseLibrary.map { it.level }.distinctSortedLevels() }
    val selectedDatasetLevel = remember(datasetPreferences.level, datasetLevels) {
        when {
            datasetLevels.contains(datasetPreferences.level) -> datasetPreferences.level
            else -> ""
        }
    }
    val datasetPrimaryMuscles = remember(exerciseLibrary) { exerciseLibrary.flatMap { it.primaryMuscles }.distinctSorted() }
    val datasetRawEquipment = remember(exerciseLibrary) { exerciseLibrary.map { it.rawEquipment }.distinctSorted() }

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
            eyebrow = "FreeExerciseDB",
            title = "Profile",
            subtitle = "Dataset fields only",
            compact = true
        )

        ProfileSection(
            title = "Dataset Summary",
            subtitle = "Available values loaded from exercises.json.",
            icon = Icons.Filled.List
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                DatasetSummaryMetric("Levels", datasetLevels.size, Icons.Filled.FlashOn, Modifier.weight(1f))
                DatasetSummaryMetric("Primary", datasetPrimaryMuscles.size, Icons.Filled.FitnessCenter, Modifier.weight(1f))
                DatasetSummaryMetric("Equipment", datasetRawEquipment.size, Icons.Filled.FitnessCenter, Modifier.weight(1f))
            }
        }

        ProfileSection(
            title = "Dataset Preferences",
            subtitle = "Dataset preferences from FreeExerciseDB.",
            icon = Icons.Filled.Flag
        ) {
            CompactDropdownRow(
                title = "Level",
                icon = Icons.Filled.FlashOn,
                value = selectedDatasetLevel.ifBlank { "All levels" },
                options = listOf("All levels") + datasetLevels,
                selectedOption = selectedDatasetLevel.ifBlank { "All levels" }
            ) { selected ->
                val nextLevel = selected.takeIf { datasetLevels.contains(it) }.orEmpty()
                updateDatasetPreferences(datasetPreferences.copy(level = nextLevel))
            }
            ProfileRowDivider()
            CompactMultiSelectRow(
                title = "Primary muscles",
                icon = Icons.Filled.FitnessCenter,
                items = datasetPrimaryMuscles,
                selected = datasetPreferences.primaryMuscles,
            ) { item ->
                updateDatasetPreferences(
                    datasetPreferences.copy(primaryMuscles = toggleInSet(datasetPreferences.primaryMuscles, item))
                )
            }
        }

        ProfileSection(
            title = "Dataset Equipment",
            subtitle = "Equipment values from the FreeExerciseDB equipment field.",
            icon = Icons.Filled.FitnessCenter
        ) {
            CompactMultiSelectRow(
                title = "Equipment",
                icon = Icons.Filled.FitnessCenter,
                items = datasetRawEquipment,
                selected = datasetPreferences.rawEquipment,
            ) { item ->
                updateDatasetPreferences(
                    datasetPreferences.copy(rawEquipment = toggleInSet(datasetPreferences.rawEquipment, item))
                )
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
private fun StartExerciseRow(exercise: ExerciseItem) {
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
            MetadataLine("Raw equipment", item.rawEquipment)
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
private fun DatasetSummaryMetric(
    title: String,
    value: Int,
    icon: ImageVector,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .padding(vertical = 14.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.42f))
            .padding(horizontal = 12.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(7.dp)
    ) {
        Icon(icon, contentDescription = null, tint = DeltsAccent, modifier = Modifier.size(22.dp))
        Text(
            text = value.toString(),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.ExtraBold,
            color = MaterialTheme.colorScheme.onBackground
        )
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
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

private fun toggleInSet(set: Set<String>, item: String): Set<String> =
    if (set.contains(item)) set - item else set + item

private fun SharedPreferences.loadDatasetPreferences(): DatasetPreferences =
    DatasetPreferences(
        level = getString("profile_experience", "").orEmpty(),
        rawEquipment = getStringSet("profile_equipment", emptySet()) ?: emptySet(),
        primaryMuscles = getStringSet("profile_focus", emptySet()) ?: emptySet()
    )

private fun SharedPreferences.saveDatasetPreferences(preferences: DatasetPreferences) {
    edit()
        .putString("profile_experience", preferences.level)
        .putStringSet("profile_equipment", preferences.rawEquipment)
        .putStringSet("profile_focus", preferences.primaryMuscles)
        .apply()
}

private enum class DeltsTab(val title: String, val icon: ImageVector) {
    Start("Start", Icons.Filled.PlayArrow),
    Workouts("Workouts", Icons.Filled.List),
    Profile("Profile", Icons.Filled.Person)
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

private data class DatasetPreferences(
    val level: String,
    val rawEquipment: Set<String>,
    val primaryMuscles: Set<String>
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
    emptyList()
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
        "Expert" -> 2
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

@Preview(showBackground = true)
@Composable
private fun DeltsAppPreview() {
    DeltsTheme {
        DeltsScreenBackground {
            StartScreen(
                exerciseLibrary = emptyList(),
                padding = PaddingValues()
            )
        }
    }
}
