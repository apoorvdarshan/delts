package com.apoorvdarshan.delts.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import com.apoorvdarshan.delts.R
import com.apoorvdarshan.delts.ui.screens.AboutScreen
import com.apoorvdarshan.delts.ui.screens.SettingsScreen
import com.apoorvdarshan.delts.ui.screens.SupportScreen
import com.apoorvdarshan.delts.ui.screens.WorkoutsScreen
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors
import com.apoorvdarshan.delts.ui.theme.ThemeController

enum class DeltsTab(val titleRes: Int, val icon: ImageVector) {
    WORKOUTS(R.string.tab_workouts, Icons.AutoMirrored.Filled.List),
    SETTINGS(R.string.tab_settings, Icons.Filled.Settings),
    SUPPORT(R.string.tab_support, Icons.Filled.Favorite),
    ABOUT(R.string.tab_about, Icons.Filled.Info)
}

@Composable
fun DeltsApp(controller: ThemeController) {
    val colors = LocalDeltsColors.current
    var tab by rememberSaveable { mutableStateOf(DeltsTab.WORKOUTS) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = colors.background,
        bottomBar = {
            NavigationBar(containerColor = colors.card) {
                DeltsTab.entries.forEach { entry ->
                    val title = stringResource(entry.titleRes)
                    NavigationBarItem(
                        selected = entry == tab,
                        onClick = { tab = entry },
                        icon = { Icon(entry.icon, contentDescription = title) },
                        label = { Text(title) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = colors.accent,
                            selectedTextColor = colors.accent,
                            indicatorColor = colors.accent.copy(alpha = 0.16f),
                            unselectedIconColor = colors.mutedText,
                            unselectedTextColor = colors.mutedText
                        )
                    )
                }
            }
        }
    ) { padding ->
        when (tab) {
            DeltsTab.WORKOUTS -> WorkoutsScreen(Modifier.padding(padding))
            DeltsTab.SETTINGS -> SettingsScreen(controller, Modifier.padding(padding))
            DeltsTab.SUPPORT -> SupportScreen(Modifier.padding(padding))
            DeltsTab.ABOUT -> AboutScreen(Modifier.padding(padding))
        }
    }
}
