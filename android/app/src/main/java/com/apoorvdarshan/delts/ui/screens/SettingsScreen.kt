package com.apoorvdarshan.delts.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.delts.ui.theme.AppAppearance
import com.apoorvdarshan.delts.ui.theme.DeltsTheme
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors
import com.apoorvdarshan.delts.ui.theme.ThemeController

@Composable
fun SettingsScreen(controller: ThemeController, modifier: Modifier = Modifier) {
    val colors = LocalDeltsColors.current

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
    ) {
        Text(
            text = "Settings",
            color = colors.charcoal,
            fontWeight = FontWeight.Bold,
            fontSize = 28.sp,
            modifier = Modifier.padding(top = 16.dp, bottom = 18.dp)
        )

        SettingsCard(title = "Theme") {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                DeltsTheme.entries.forEach { theme ->
                    val selected = controller.theme == theme
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .background(theme.accent(colors.isDark))
                            .border(
                                width = if (selected) 3.dp else 0.dp,
                                color = colors.charcoal,
                                shape = CircleShape
                            )
                            .clickable { controller.selectTheme(theme) },
                        contentAlignment = Alignment.Center
                    ) {
                        if (selected) {
                            Icon(
                                Icons.Filled.Check,
                                contentDescription = theme.title,
                                tint = colors.onAccent
                            )
                        }
                    }
                }
            }
        }

        SettingsCard(title = "Appearance") {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                AppAppearance.entries.forEach { option ->
                    val selected = controller.appearance == option
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(
                                if (selected) colors.accent.copy(alpha = 0.16f) else colors.panel.copy(alpha = 0.4f)
                            )
                            .clickable { controller.selectAppearance(option) }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = option.title,
                            color = if (selected) colors.charcoal else colors.mutedText,
                            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                            modifier = Modifier.weight(1f)
                        )
                        if (selected) {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = colors.accent)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SettingsCard(title: String, content: @Composable () -> Unit) {
    val colors = LocalDeltsColors.current
    Text(
        text = title,
        color = colors.mutedText,
        fontWeight = FontWeight.Bold,
        fontSize = 15.sp,
        modifier = Modifier.padding(start = 14.dp, bottom = 8.dp)
    )
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp))
            .background(colors.panel.copy(alpha = 0.18f))
            .border(0.5.dp, colors.hairline.copy(alpha = 0.22f), RoundedCornerShape(28.dp))
            .padding(16.dp)
    ) {
        content()
    }
    androidx.compose.foundation.layout.Spacer(Modifier.size(18.dp))
}
