package com.apoorvdarshan.delts.ui.screens

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.BugReport
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.SystemUpdate
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
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.delts.ui.components.ActionRow
import com.apoorvdarshan.delts.ui.components.DeltsCard
import com.apoorvdarshan.delts.ui.components.RowDivider
import com.apoorvdarshan.delts.ui.components.SectionTitle
import com.apoorvdarshan.delts.ui.theme.AppAppearance
import com.apoorvdarshan.delts.ui.theme.DeltsTheme
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors
import com.apoorvdarshan.delts.ui.theme.ThemeController

private val releaseHighlights = listOf(
    "Delts is a free, focused exercise library — browse hundreds of moves with form instructions and rich filters.",
    "Built around four simple tabs: Workouts, Settings, Support, and About.",
    "Completely private — no account, no ads, no tracking. Everything stays on your device.",
    "Lighter and faster, with a clean layout and five color themes."
)

@Composable
fun SettingsScreen(controller: ThemeController, modifier: Modifier = Modifier) {
    val colors = LocalDeltsColors.current
    val context = LocalContext.current
    val version = remember {
        runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }.getOrNull() ?: "1.0"
    }

    Column(
        modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 8.dp, bottom = 32.dp)
    ) {
        SectionTitle("App Preferences")
        DeltsCard {
            ThemeBlock(controller)
            RowDivider()
            AppearanceBlock(controller)
        }

        SectionTitle("Release")
        DeltsCard {
            ActionRow("Check for Updates", Icons.Filled.SystemUpdate, version) {
                openUrl(context, "https://play.google.com/store/apps/details?id=com.apoorvdarshan.delts")
            }
            RowDivider()
            WhatsNewRow(version)
        }

        SectionTitle("Feedback")
        DeltsCard {
            ActionRow("Report an Issue", Icons.Filled.BugReport, "GitHub", tint = Color(0xFFE5534B)) {
                openUrl(context, "https://github.com/apoorvdarshan/delts/issues/new")
            }
            RowDivider()
            ActionRow("Request a Feature", Icons.Filled.Lightbulb, "GitHub") {
                openUrl(context, "https://github.com/apoorvdarshan/delts/issues/new?labels=enhancement")
            }
        }
    }
}

@Composable
private fun ThemeBlock(controller: ThemeController) {
    val colors = LocalDeltsColors.current
    Column(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Theme", color = colors.charcoal, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            DeltsTheme.entries.forEach { theme ->
                val selected = controller.theme == theme
                Box(
                    Modifier
                        .size(46.dp)
                        .clip(CircleShape)
                        .background(theme.accent(colors.isDark))
                        .border(if (selected) 3.dp else 0.dp, colors.charcoal, CircleShape)
                        .clickable { controller.selectTheme(theme) },
                    contentAlignment = Alignment.Center
                ) {
                    if (selected) Icon(Icons.Filled.Check, theme.title, tint = colors.onAccent, modifier = Modifier.size(20.dp))
                }
            }
        }
    }
}

@Composable
private fun AppearanceBlock(controller: ThemeController) {
    val colors = LocalDeltsColors.current
    Column(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Appearance", color = colors.charcoal, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            AppAppearance.entries.forEach { option ->
                val selected = controller.appearance == option
                Box(
                    Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(12.dp))
                        .background(if (selected) colors.accent.copy(alpha = 0.16f) else colors.panel.copy(alpha = 0.40f))
                        .border(
                            0.5.dp,
                            if (selected) colors.accent.copy(alpha = 0.6f) else colors.hairline.copy(alpha = 0.24f),
                            RoundedCornerShape(12.dp)
                        )
                        .clickable { controller.selectAppearance(option) }
                        .padding(vertical = 10.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        option.title,
                        color = if (selected) colors.charcoal else colors.mutedText,
                        fontSize = 12.sp,
                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                        maxLines = 1
                    )
                }
            }
        }
    }
}

@Composable
private fun WhatsNewRow(version: String) {
    val colors = LocalDeltsColors.current
    var expanded by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().clickable { expanded = !expanded }.heightIn(min = 52.dp).padding(vertical = 9.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(11.dp)
        ) {
            Box(Modifier.size(38.dp), contentAlignment = Alignment.CenterStart) {
                Icon(Icons.Filled.AutoAwesome, null, tint = colors.secondaryAccent, modifier = Modifier.size(21.dp))
            }
            Text("What's New", color = colors.charcoal, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight, null,
                tint = colors.mutedText.copy(alpha = 0.72f),
                modifier = Modifier.size(20.dp).rotate(if (expanded) 90f else 0f)
            )
        }
        AnimatedVisibility(expanded) {
            Column(Modifier.padding(start = 49.dp, end = 4.dp, bottom = 14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Delts $version", color = colors.charcoal, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                releaseHighlights.forEach { line ->
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Icon(Icons.Filled.CheckCircle, null, tint = colors.accent, modifier = Modifier.size(15.dp).padding(top = 1.dp))
                        Text(line, color = colors.mutedText, fontSize = 14.sp, lineHeight = 19.sp)
                    }
                }
            }
        }
    }
}

private fun openUrl(context: Context, url: String) {
    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
}
