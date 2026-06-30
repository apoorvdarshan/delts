package com.apoorvdarshan.delts

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.apoorvdarshan.delts.ui.DeltsApp
import com.apoorvdarshan.delts.ui.theme.DeltsAppTheme
import com.apoorvdarshan.delts.ui.theme.ThemeController

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val controller = ThemeController.from(this)
        setContent {
            DeltsAppTheme(controller) {
                DeltsApp(controller)
            }
        }
    }
}
