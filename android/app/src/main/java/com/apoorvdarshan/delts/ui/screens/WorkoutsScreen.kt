package com.apoorvdarshan.delts.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.delts.data.ExerciseRepository
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors

@Composable
fun WorkoutsScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val repo = remember { ExerciseRepository.get(context) }
    val colors = LocalDeltsColors.current

    Column(modifier = modifier.fillMaxSize()) {
        Text(
            text = "Workouts",
            color = colors.charcoal,
            fontWeight = FontWeight.Bold,
            fontSize = 28.sp,
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 16.dp)
        )
        Text(
            text = "${repo.exercises.size} exercises",
            color = colors.mutedText,
            fontSize = 14.sp,
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 2.dp, bottom = 8.dp)
        )
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(repo.exercises, key = { it.id }) { item ->
                Text(
                    text = item.name,
                    color = colors.charcoal,
                    fontSize = 16.sp,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                )
                HorizontalDivider(color = colors.hairline.copy(alpha = 0.28f), thickness = 0.5.dp)
            }
        }
    }
}
