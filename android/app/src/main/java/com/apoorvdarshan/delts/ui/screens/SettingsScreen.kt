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
import androidx.compose.foundation.layout.offset
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
import androidx.compose.material.icons.filled.Contrast
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.SystemUpdate
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.apoorvdarshan.delts.R
import com.apoorvdarshan.delts.ui.components.ActionRow
import com.apoorvdarshan.delts.ui.components.DeltsCard
import com.apoorvdarshan.delts.ui.components.RowDivider
import com.apoorvdarshan.delts.ui.components.SectionTitle
import com.apoorvdarshan.delts.ui.theme.AppAppearance
import com.apoorvdarshan.delts.ui.theme.DeltsTheme
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors
import com.apoorvdarshan.delts.ui.theme.ThemeController

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
        SectionTitle(stringResource(R.string.sec_app_preferences))
        Text(
            stringResource(R.string.app_preferences_subtitle),
            color = colors.mutedText, fontSize = 13.sp,
            modifier = Modifier.padding(start = 14.dp, bottom = 8.dp)
        )
        DeltsCard {
            ThemeBlock(controller)
            RowDivider()
            AppearanceBlock(controller)
        }

        SectionTitle(stringResource(R.string.sec_release))
        DeltsCard {
            ActionRow(stringResource(R.string.check_for_updates), Icons.Filled.SystemUpdate, version) {
                openUrl(context, "https://play.google.com/store/apps/details?id=com.apoorvdarshan.delts")
            }
            RowDivider()
            WhatsNewRow(version)
        }

        SectionTitle(stringResource(R.string.sec_feedback))
        DeltsCard {
            ActionRow(stringResource(R.string.report_issue), Icons.Filled.BugReport, stringResource(R.string.value_github), tint = Color(0xFFE5534B)) {
                openUrl(context, "https://github.com/apoorvdarshan/delts/issues/new")
            }
            RowDivider()
            ActionRow(stringResource(R.string.request_feature), Icons.Filled.Lightbulb, stringResource(R.string.value_github)) {
                openUrl(context, "https://github.com/apoorvdarshan/delts/issues/new?labels=enhancement")
            }
        }
    }
}

@Composable
private fun ThemeBlock(controller: ThemeController) {
    val colors = LocalDeltsColors.current
    Column(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(11.dp)) {
            Box(Modifier.size(38.dp), contentAlignment = Alignment.CenterStart) {
                Icon(Icons.Filled.Palette, null, tint = colors.secondaryAccent, modifier = Modifier.size(21.dp))
            }
            Text(stringResource(R.string.pref_theme), color = colors.charcoal, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            DeltsTheme.entries.forEach { theme ->
                val selected = controller.theme == theme
                // iOS previewColor is always the vivid DARK accent, even in Light appearance.
                val accent = theme.accent(dark = true)
                Column(
                    Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(16.dp))
                        .background(if (selected) accent.copy(alpha = 0.16f) else colors.panel.copy(alpha = 0.20f))
                        .border(
                            if (selected) 1.2.dp else 0.6.dp,
                            if (selected) accent.copy(alpha = 0.78f) else colors.hairline.copy(alpha = 0.26f),
                            RoundedCornerShape(16.dp)
                        )
                        .clickable { controller.selectTheme(theme) }
                        .padding(vertical = 8.dp, horizontal = 4.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Box(contentAlignment = Alignment.TopEnd) {
                        AsyncImage(
                            model = "file:///android_asset/brand/theme_${theme.name.lowercase()}.png",
                            contentDescription = stringResource(theme.titleRes),
                            modifier = Modifier
                                .size(42.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .border(0.6.dp, colors.hairline.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
                        )
                        if (selected) {
                            Icon(
                                Icons.Filled.Check, null, tint = accent,
                                modifier = Modifier
                                    .offset(x = 4.dp, y = (-4).dp)
                                    .size(16.dp)
                                    .clip(CircleShape)
                                    .background(Color.Black.copy(alpha = 0.86f))
                                    .padding(1.dp)
                            )
                        }
                    }
                    Text(
                        stringResource(theme.titleRes),
                        color = if (selected) colors.charcoal else colors.mutedText,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Black,
                        maxLines = 1
                    )
                }
            }
        }
    }
}

@Composable
private fun AppearanceBlock(controller: ThemeController) {
    val colors = LocalDeltsColors.current
    var expanded by remember { mutableStateOf(false) }
    Box {
        Row(
            Modifier.fillMaxWidth().heightIn(min = 52.dp).clickable { expanded = true }.padding(vertical = 9.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(11.dp)
        ) {
            Box(Modifier.size(38.dp), contentAlignment = Alignment.CenterStart) {
                Icon(Icons.Filled.Contrast, null, tint = colors.secondaryAccent, modifier = Modifier.size(21.dp))
            }
            Text(stringResource(R.string.pref_appearance), color = colors.charcoal, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            Text(stringResource(controller.appearance.titleRes), color = colors.mutedText, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
            Icon(Icons.Filled.UnfoldMore, null, tint = colors.mutedText, modifier = Modifier.size(18.dp))
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            containerColor = colors.card,
            shape = RoundedCornerShape(16.dp)
        ) {
            AppAppearance.entries.forEach { option ->
                val sel = controller.appearance == option
                DropdownMenuItem(
                    text = { Text(stringResource(option.titleRes), color = if (sel) colors.accent else colors.charcoal, fontWeight = if (sel) FontWeight.Bold else FontWeight.Normal) },
                    onClick = { controller.selectAppearance(option); expanded = false },
                    trailingIcon = if (sel) {
                        { Icon(Icons.Filled.Check, null, tint = colors.accent) }
                    } else null
                )
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
            Text(stringResource(R.string.whats_new), color = colors.charcoal, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight, null,
                tint = colors.mutedText.copy(alpha = 0.72f),
                modifier = Modifier.size(20.dp).rotate(if (expanded) 90f else 0f)
            )
        }
        AnimatedVisibility(expanded) {
            val highlights = listOf(
                stringResource(R.string.highlight_1),
                stringResource(R.string.highlight_2),
                stringResource(R.string.highlight_3),
                stringResource(R.string.highlight_4)
            )
            Column(Modifier.padding(start = 49.dp, end = 4.dp, bottom = 14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(stringResource(R.string.whats_new_version, version), color = colors.charcoal, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                highlights.forEach { line ->
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
