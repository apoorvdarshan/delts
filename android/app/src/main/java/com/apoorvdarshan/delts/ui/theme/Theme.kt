package com.apoorvdarshan.delts.ui.theme

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf

/** Provides the resolved Delts palette to the tree (the analog of `Color.delts*`). */
val LocalDeltsColors = staticCompositionLocalOf {
    deltsColors(DeltsTheme.LIME, dark = true, darker = false)
}

/**
 * App-wide theme + appearance state, persisted to SharedPreferences — the analog
 * of the iOS `@AppStorage(DeltsTheme.storageKey)` / `AppAppearance.storageKey`.
 */
class ThemeController(private val context: Context) {
    private val prefs = context.getSharedPreferences("delts_prefs", Context.MODE_PRIVATE)

    var theme by mutableStateOf(readTheme())
        private set
    var appearance by mutableStateOf(readAppearance())
        private set

    fun selectTheme(value: DeltsTheme) {
        theme = value
        prefs.edit().putString(KEY_THEME, value.name).apply()
        applyLauncherIcon(value)
    }

    /** Swaps the home-screen icon to the chosen accent via activity-aliases (iOS parity). */
    private fun applyLauncherIcon(value: DeltsTheme) {
        val pm = context.packageManager
        val pkg = context.packageName
        val aliasFor = mapOf(
            DeltsTheme.LIME to "LimeAlias",
            DeltsTheme.CYAN to "CyanAlias",
            DeltsTheme.PINK to "PinkAlias",
            DeltsTheme.AMBER to "AmberAlias",
            DeltsTheme.VIOLET to "VioletAlias"
        )
        // Enable the target first so the package never has zero launcher components.
        aliasFor[value]?.let {
            pm.setComponentEnabledSetting(
                ComponentName(pkg, "$pkg.$it"),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
        }
        aliasFor.forEach { (t, name) ->
            if (t != value) {
                pm.setComponentEnabledSetting(
                    ComponentName(pkg, "$pkg.$name"),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
        }
    }

    fun selectAppearance(value: AppAppearance) {
        appearance = value
        prefs.edit().putString(KEY_APPEARANCE, value.name).apply()
    }

    private fun readTheme(): DeltsTheme =
        runCatching { DeltsTheme.valueOf(prefs.getString(KEY_THEME, null) ?: "") }
            .getOrDefault(DeltsTheme.LIME)

    private fun readAppearance(): AppAppearance =
        runCatching { AppAppearance.valueOf(prefs.getString(KEY_APPEARANCE, null) ?: "") }
            .getOrDefault(AppAppearance.SYSTEM)

    companion object {
        private const val KEY_THEME = "delts_theme"
        private const val KEY_APPEARANCE = "app_appearance"

        fun from(context: Context): ThemeController =
            ThemeController(context.applicationContext)
    }
}

@Composable
fun DeltsAppTheme(
    controller: ThemeController,
    content: @Composable () -> Unit
) {
    val systemDark = isSystemInDarkTheme()
    val appearance = controller.appearance
    val dark = when (appearance) {
        AppAppearance.SYSTEM -> systemDark
        AppAppearance.LIGHT -> false
        AppAppearance.DARK, AppAppearance.DARKER -> true
    }
    val darker = appearance == AppAppearance.DARKER
    val colors = deltsColors(controller.theme, dark, darker)

    val scheme = if (dark) {
        darkColorScheme(
            primary = colors.accent,
            onPrimary = colors.onAccent,
            secondary = colors.secondaryAccent,
            background = colors.background,
            onBackground = colors.charcoal,
            surface = colors.card,
            onSurface = colors.charcoal,
            surfaceVariant = colors.panel,
            outline = colors.hairline
        )
    } else {
        lightColorScheme(
            primary = colors.accent,
            onPrimary = colors.onAccent,
            secondary = colors.secondaryAccent,
            background = colors.background,
            onBackground = colors.charcoal,
            surface = colors.card,
            onSurface = colors.charcoal,
            surfaceVariant = colors.panel,
            outline = colors.hairline
        )
    }

    CompositionLocalProvider(LocalDeltsColors provides colors) {
        MaterialTheme(
            colorScheme = scheme,
            typography = Typography,
            content = content
        )
    }
}
