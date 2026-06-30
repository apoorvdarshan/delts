package com.apoorvdarshan.delts.ui.components

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.layout.ContentScale
import coil.compose.AsyncImage
import com.apoorvdarshan.delts.data.ExerciseRepository
import kotlinx.coroutines.delay

/**
 * Muted, cross-fading exercise visual — the Android analog of the iOS
 * `AnimatedExerciseVisual`. Cycles through the exercise's images every 0.85s and
 * applies the same desaturated / higher-contrast / slightly-darker treatment.
 */
private val ExerciseImageFilter: ColorFilter = run {
    // saturation(0.30) then grayscale(0.36) ≈ net saturation ~0.19
    val saturation = ColorMatrix().apply { setToSaturation(0.19f) }
    val contrast = 1.10f
    val translate = (1f - contrast) * 127.5f + (-0.05f * 255f) // contrast pivot + brightness(-0.05)
    val contrastBrightness = ColorMatrix(
        floatArrayOf(
            contrast, 0f, 0f, 0f, translate,
            0f, contrast, 0f, 0f, translate,
            0f, 0f, contrast, 0f, translate,
            0f, 0f, 0f, 1f, 0f
        )
    )
    contrastBrightness.timesAssign(saturation) // apply saturation first, then contrast+brightness
    ColorFilter.colorMatrix(contrastBrightness)
}

@Composable
fun AnimatedExerciseImage(
    imagePaths: List<String>,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop
) {
    var index by remember(imagePaths) { mutableIntStateOf(0) }

    LaunchedEffect(imagePaths) {
        if (imagePaths.size > 1) {
            while (true) {
                delay(850)
                index = (index + 1) % imagePaths.size
            }
        }
    }

    Crossfade(targetState = index, animationSpec = tween(durationMillis = 450), label = "exercise-frame") { i ->
        val path = imagePaths.getOrNull(i)
        if (path != null) {
            AsyncImage(
                model = ExerciseRepository.imageAssetUri(path),
                contentDescription = null,
                contentScale = contentScale,
                colorFilter = ExerciseImageFilter,
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}
