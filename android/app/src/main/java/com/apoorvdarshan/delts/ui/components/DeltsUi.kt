package com.apoorvdarshan.delts.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors

/** Screen title (large), like the iOS inline nav titles. */
@Composable
fun ScreenTitle(text: String) {
    val colors = LocalDeltsColors.current
    Text(
        text,
        color = colors.charcoal,
        fontSize = 28.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(top = 16.dp, bottom = 6.dp)
    )
}

/** Section header — `.callout.bold` muted, mirroring iOS AboutSection title. */
@Composable
fun SectionTitle(text: String) {
    val colors = LocalDeltsColors.current
    Text(
        text,
        color = colors.mutedText,
        fontSize = 15.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(start = 14.dp, bottom = 8.dp, top = 18.dp)
    )
}

/** Rounded panel card grouping rows — mirrors iOS AboutRowStack. */
@Composable
fun DeltsCard(content: @Composable ColumnScope.() -> Unit) {
    val colors = LocalDeltsColors.current
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp))
            .background(colors.panel.copy(alpha = 0.18f))
            .border(0.5.dp, colors.hairline.copy(alpha = 0.22f), RoundedCornerShape(28.dp))
            .padding(horizontal = 14.dp)
    ) {
        content()
    }
}

/** Leading-inset hairline divider between rows. */
@Composable
fun RowDivider() {
    val colors = LocalDeltsColors.current
    HorizontalDivider(color = colors.hairline.copy(alpha = 0.28f), thickness = 0.5.dp, modifier = Modifier.padding(start = 48.dp))
}

/** Tappable row: icon + title + value + chevron — mirrors iOS AboutActionRow. */
@Composable
fun ActionRow(
    title: String,
    icon: ImageVector,
    value: String? = null,
    tint: Color = LocalDeltsColors.current.secondaryAccent,
    showChevron: Boolean = true,
    onClick: () -> Unit
) {
    val colors = LocalDeltsColors.current
    Row(
        Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .heightIn(min = 52.dp)
            .padding(vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(11.dp)
    ) {
        Box(Modifier.width(38.dp), contentAlignment = Alignment.CenterStart) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(21.dp))
        }
        Text(
            title,
            color = colors.charcoal,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f)
        )
        if (value != null) {
            Text(
                value,
                color = colors.mutedText,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        if (showChevron) {
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = colors.mutedText.copy(alpha = 0.72f),
                modifier = Modifier.size(18.dp)
            )
        }
    }
}
