package com.apoorvdarshan.delts.ui.screens

import android.content.Context
import android.content.Intent
import android.net.Uri
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
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
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors

@Composable
fun AboutScreen(modifier: Modifier = Modifier) {
    val colors = LocalDeltsColors.current
    val context = LocalContext.current

    Column(
        modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 8.dp, bottom = 32.dp)
    ) {
        SectionTitle(stringResource(R.string.sec_built_by))
        DeltsCard {
            ActionRow("Apoorv Darshan", Icons.Filled.Person, stringResource(R.string.creator)) {
                openUrl(context, "https://x.com/apoorvdarshan")
            }
        }
        Spacer(Modifier.size(14.dp))
        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(28.dp))
                .background(colors.panel.copy(alpha = 0.18f))
                .border(0.5.dp, colors.hairline.copy(alpha = 0.22f), RoundedCornerShape(28.dp))
                .padding(vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            AsyncImage(
                model = "file:///android_asset/brand/ace_badge.png",
                contentDescription = stringResource(R.string.ace_cert),
                contentScale = ContentScale.Fit,
                modifier = Modifier.size(104.dp)
            )
            Text(stringResource(R.string.ace_cert), color = colors.mutedText, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
        }

        SectionTitle(stringResource(R.string.sec_also_by))
        DeltsCard {
            FudAIPromoRow { openUrl(context, "https://apps.apple.com/app/id6758935726") }
        }

        SectionTitle(stringResource(R.string.sec_legal))
        DeltsCard {
            ActionRow(stringResource(R.string.privacy_policy), Icons.Filled.Shield, "delts.fit/privacy") {
                openUrl(context, "https://delts.fit/privacy.html")
            }
            RowDivider()
            ActionRow(stringResource(R.string.terms), Icons.Filled.Description, "delts.fit/terms") {
                openUrl(context, "https://delts.fit/terms.html")
            }
        }
    }
}

@Composable
private fun FudAIPromoRow(onClick: () -> Unit) {
    val colors = LocalDeltsColors.current
    Row(
        Modifier.fillMaxWidth().clickable { onClick() }.padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        AsyncImage(
            model = "file:///android_asset/brand/fud_ai_icon.png",
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .size(54.dp)
                .clip(RoundedCornerShape(12.dp))
                .border(0.5.dp, colors.hairline.copy(alpha = 0.4f), RoundedCornerShape(12.dp))
        )
        Column(Modifier.weight(1f)) {
            Text("Fud AI", color = colors.charcoal, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            Text(stringResource(R.string.fud_descriptor), color = colors.mutedText, fontSize = 14.sp)
        }
        Box(
            Modifier
                .clip(CircleShape)
                .background(colors.accent.copy(alpha = 0.16f))
                .padding(horizontal = 16.dp, vertical = 7.dp)
        ) {
            Text(stringResource(R.string.get), color = colors.accent, fontSize = 14.sp, fontWeight = FontWeight.Bold)
        }
    }
}

private fun openUrl(context: Context, url: String) {
    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
}
