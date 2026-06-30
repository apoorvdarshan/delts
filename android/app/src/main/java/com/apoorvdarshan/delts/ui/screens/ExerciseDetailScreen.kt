package com.apoorvdarshan.delts.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.Tag
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.apoorvdarshan.delts.data.ExerciseItem
import com.apoorvdarshan.delts.data.ExerciseRepository
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors

@Composable
fun ExerciseDetailScreen(item: ExerciseItem, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val colors = LocalDeltsColors.current
    var showMetrics by remember { mutableStateOf(false) }

    Column(modifier.fillMaxSize()) {
        // Top bar: back + title
        Row(
            Modifier
                .fillMaxWidth()
                .background(colors.background)
                .padding(horizontal = 8.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint = colors.accent,
                modifier = Modifier.size(40.dp).clip(CircleShape).clickable { onBack() }.padding(8.dp)
            )
            Text(
                item.name,
                color = colors.charcoal,
                fontSize = 17.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                modifier = Modifier.weight(1f).padding(horizontal = 8.dp)
            )
            Spacer(Modifier.size(40.dp))
        }

        LazyColumn(Modifier.fillMaxSize()) {
            item(key = "hero") {
                Box(Modifier.fillMaxWidth().height(294.dp)) {
                    val firstImage = item.imagePaths.firstOrNull()
                    if (firstImage != null) {
                        AsyncImage(
                            model = ExerciseRepository.imageAssetUri(firstImage),
                            contentDescription = "${item.name} visual",
                            contentScale = ContentScale.Crop,
                            modifier = Modifier.fillMaxSize().background(colors.panel.copy(alpha = 0.32f))
                        )
                    } else {
                        Box(Modifier.fillMaxSize().background(colors.panel.copy(alpha = 0.32f)))
                    }

                    if (showMetrics) {
                        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.5f)))
                        MetricGrid(item, Modifier.padding(start = 20.dp, top = 12.dp, end = 80.dp))
                    }

                    // Info toggle (top-right)
                    Icon(
                        Icons.Filled.Info,
                        contentDescription = if (showMetrics) "Hide details" else "Show details",
                        tint = colors.accent,
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(14.dp)
                            .size(44.dp)
                            .clip(CircleShape)
                            .background(colors.background.copy(alpha = 0.78f))
                            .border(0.7.dp, colors.hairline.copy(alpha = 0.42f), CircleShape)
                            .clickable { showMetrics = !showMetrics }
                            .padding(10.dp)
                    )
                }
            }

            item(key = "instructions") {
                InstructionSection(item.instructions, Modifier.padding(horizontal = 20.dp, vertical = 24.dp))
            }
            item(key = "pad") { Spacer(Modifier.size(40.dp)) }
        }
    }
}

@Composable
private fun MetricGrid(item: ExerciseItem, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            MetricCard("Level", item.level, Icons.Filled.BarChart, Modifier.weight(1f))
            MetricCard("Category", item.category, Icons.Filled.Tag, Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            MetricCard("Force", item.force, Icons.Filled.SwapHoriz, Modifier.weight(1f))
            MetricCard("Mechanic", item.mechanic, Icons.Filled.Settings, Modifier.weight(1f))
        }
        MetricCard("Primary", item.primaryMusclesTitle, Icons.Filled.GpsFixed, Modifier.fillMaxWidth())
        MetricCard("Secondary", item.secondaryMusclesTitle, Icons.Filled.GpsFixed, Modifier.fillMaxWidth())
        MetricCard("Equipment", item.equipment, Icons.Filled.FitnessCenter, Modifier.fillMaxWidth())
    }
}

@Composable
private fun MetricCard(title: String, value: String, icon: androidx.compose.ui.graphics.vector.ImageVector, modifier: Modifier = Modifier) {
    val colors = LocalDeltsColors.current
    Column(
        modifier
            .clip(RoundedCornerShape(16.dp))
            .background(colors.background.copy(alpha = 0.55f))
            .border(0.6.dp, colors.hairline.copy(alpha = 0.32f), RoundedCornerShape(16.dp))
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Icon(icon, null, tint = colors.accent, modifier = Modifier.size(11.dp))
            Text(title, color = colors.accent, fontSize = 10.sp, fontWeight = FontWeight.Bold, maxLines = 1)
        }
        Text(value, color = colors.charcoal, fontSize = 14.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun InstructionSection(instructions: List<String>, modifier: Modifier = Modifier) {
    val colors = LocalDeltsColors.current
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(
                Modifier.size(30.dp).clip(RoundedCornerShape(10.dp)).background(colors.accent.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Text("≣", color = colors.accent, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            }
            Text("Instructions", color = colors.charcoal, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.weight(1f))
            Box(
                Modifier.clip(CircleShape).background(colors.secondaryAccent.copy(alpha = 0.12f)).padding(horizontal = 9.dp, vertical = 4.dp)
            ) {
                Text("${instructions.size}", color = colors.secondaryAccent, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            instructions.forEachIndexed { index, instruction ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(18.dp))
                        .background(colors.panel.copy(alpha = 0.16f))
                        .border(0.5.dp, colors.hairline.copy(alpha = 0.20f), RoundedCornerShape(18.dp))
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.spacedBy(13.dp)
                ) {
                    Box(
                        Modifier.size(27.dp).clip(CircleShape).background(colors.accent),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("${index + 1}", color = colors.onAccent, fontSize = 13.sp, fontWeight = FontWeight.Black)
                    }
                    Text(
                        instruction,
                        color = colors.charcoal.copy(alpha = 0.86f),
                        fontSize = 15.sp,
                        lineHeight = 21.sp,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}
