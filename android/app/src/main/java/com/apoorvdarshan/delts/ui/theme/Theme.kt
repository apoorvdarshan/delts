package com.apoorvdarshan.delts.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = DeltsAccent,
    onPrimary = DeltsOnAccent,
    secondary = DeltsSecondaryAccent,
    tertiary = DeltsWarning,
    background = DeltsBackgroundDark,
    onBackground = DeltsCharcoalDark,
    surface = DeltsCardDark,
    surfaceVariant = DeltsPanelDark,
    onSurface = DeltsCharcoalDark,
    onSurfaceVariant = DeltsMutedDark,
    outline = DeltsHairlineDark,
    outlineVariant = DeltsHairlineDark
)

private val LightColorScheme = lightColorScheme(
    primary = DeltsAccent,
    onPrimary = DeltsOnAccent,
    secondary = DeltsSecondaryAccent,
    tertiary = DeltsWarning,
    background = DeltsBackgroundLight,
    onBackground = DeltsCharcoalLight,
    surface = DeltsCardLight,
    surfaceVariant = DeltsPanelLight,
    onSurface = DeltsCharcoalLight,
    onSurfaceVariant = DeltsMutedLight,
    outline = DeltsHairlineLight,
    outlineVariant = DeltsHairlineLight
)

@Composable
fun DeltsTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
