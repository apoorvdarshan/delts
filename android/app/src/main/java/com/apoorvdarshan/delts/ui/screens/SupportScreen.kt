package com.apoorvdarshan.delts.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors

@Composable
fun SupportScreen(modifier: Modifier = Modifier) {
    val colors = LocalDeltsColors.current
    Column(modifier = modifier.fillMaxSize().padding(horizontal = 20.dp)) {
        Text(
            text = "Support",
            color = colors.charcoal,
            fontWeight = FontWeight.Bold,
            fontSize = 28.sp,
            modifier = Modifier.padding(top = 16.dp)
        )
        Text(
            text = "Connect, share, and tip jar coming next.",
            color = colors.mutedText,
            fontSize = 14.sp,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}
