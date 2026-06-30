package com.apoorvdarshan.delts.ui.theme

import androidx.compose.ui.graphics.Color
import com.apoorvdarshan.delts.R

/** sRGB component helper mirroring the iOS UIColor(red:green:blue:) values 1:1. */
private fun rgb(r: Double, g: Double, b: Double) = Color(r.toFloat(), g.toFloat(), b.toFloat(), 1f)

/** The five accent themes, mirroring iOS `DeltsTheme`. */
enum class DeltsTheme(val titleRes: Int) {
    LIME(R.string.theme_lime),
    CYAN(R.string.theme_cyan),
    PINK(R.string.theme_pink),
    AMBER(R.string.theme_amber),
    VIOLET(R.string.theme_violet);

    fun accent(dark: Boolean): Color = when (this) {
        LIME -> if (dark) rgb(0.70, 0.94, 0.26) else rgb(0.374, 0.565, 0.075)
        CYAN -> if (dark) rgb(0.140, 0.870, 0.960) else rgb(0.000, 0.478, 0.620)
        PINK -> if (dark) rgb(1.000, 0.330, 0.570) else rgb(0.780, 0.100, 0.340)
        AMBER -> if (dark) rgb(1.000, 0.710, 0.180) else rgb(0.700, 0.370, 0.020)
        VIOLET -> if (dark) rgb(0.660, 0.540, 1.000) else rgb(0.420, 0.260, 0.780)
    }

    fun secondary(dark: Boolean): Color = when (this) {
        LIME -> if (dark) rgb(0.35, 0.78, 0.52) else rgb(0.192, 0.494, 0.280)
        CYAN -> if (dark) rgb(0.250, 0.720, 0.880) else rgb(0.060, 0.400, 0.640)
        PINK -> if (dark) rgb(1.000, 0.540, 0.720) else rgb(0.600, 0.120, 0.330)
        AMBER -> if (dark) rgb(0.920, 0.560, 0.160) else rgb(0.560, 0.300, 0.060)
        VIOLET -> if (dark) rgb(0.560, 0.700, 1.000) else rgb(0.300, 0.380, 0.760)
    }
}

/** Display appearance options, mirroring iOS `AppAppearance`. */
enum class AppAppearance(val titleRes: Int) {
    SYSTEM(R.string.appearance_system),
    LIGHT(R.string.appearance_light),
    DARK(R.string.appearance_dark),
    DARKER(R.string.appearance_darker)
}

/** Resolved Delts palette for the current theme + appearance (the iOS `Color.delts*` set). */
data class DeltsColors(
    val background: Color,
    val charcoal: Color,
    val card: Color,
    val panel: Color,
    val hairline: Color,
    val accent: Color,
    val secondaryAccent: Color,
    val warning: Color,
    val onAccent: Color,
    val mutedText: Color,
    val isDark: Boolean
)

/** Builds the palette exactly as the iOS `AppTheme.swift` dynamic colors do. */
fun deltsColors(theme: DeltsTheme, dark: Boolean, darker: Boolean): DeltsColors {
    val background = when {
        darker -> rgb(0.000, 0.000, 0.000)
        dark -> rgb(0.047, 0.055, 0.052)
        else -> rgb(0.918, 0.953, 0.845)
    }
    val charcoal = when {
        darker -> rgb(0.940, 0.975, 0.910)
        dark -> rgb(0.890, 0.935, 0.865)
        else -> rgb(0.056, 0.080, 0.066)
    }
    val card = when {
        darker -> rgb(0.024, 0.026, 0.023)
        dark -> rgb(0.090, 0.108, 0.098)
        else -> rgb(0.846, 0.914, 0.752)
    }
    val panel = when {
        darker -> rgb(0.038, 0.043, 0.038)
        dark -> rgb(0.124, 0.150, 0.132)
        else -> rgb(0.768, 0.864, 0.640)
    }
    val hairline = when {
        darker -> rgb(0.300, 0.405, 0.305)
        dark -> rgb(0.286, 0.366, 0.304)
        else -> rgb(0.368, 0.516, 0.282)
    }
    val mutedText = when {
        darker -> rgb(0.690, 0.765, 0.675)
        dark -> rgb(0.620, 0.710, 0.622)
        else -> rgb(0.236, 0.322, 0.220)
    }
    val warning = if (dark) rgb(0.76, 0.88, 0.24) else rgb(0.438, 0.568, 0.084)
    val onAccent = if (dark) rgb(0.032, 0.048, 0.038) else rgb(0.972, 1.000, 0.900)
    return DeltsColors(
        background = background,
        charcoal = charcoal,
        card = card,
        panel = panel,
        hairline = hairline,
        accent = theme.accent(dark),
        secondaryAccent = theme.secondary(dark),
        warning = warning,
        onAccent = onAccent,
        mutedText = mutedText,
        isDark = dark
    )
}
