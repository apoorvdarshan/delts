package com.apoorvdarshan.delts.ui.screens

import android.app.Activity
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AlternateEmail
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.android.billingclient.api.ProductDetails
import com.apoorvdarshan.delts.billing.TipBillingManager
import com.apoorvdarshan.delts.ui.components.ActionRow
import com.apoorvdarshan.delts.ui.components.DeltsCard
import com.apoorvdarshan.delts.ui.components.RowDivider
import com.apoorvdarshan.delts.ui.components.SectionTitle
import com.apoorvdarshan.delts.ui.theme.LocalDeltsColors

@Composable
fun SupportScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val manager = remember { TipBillingManager(context.applicationContext) }
    DisposableEffect(Unit) {
        manager.connect()
        onDispose { manager.release() }
    }

    Column(
        modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 8.dp, bottom = 32.dp)
    ) {
        SectionTitle("Connect")
        DeltsCard {
            ActionRow("Contact Us", Icons.Filled.Email, "ad13dtu@gmail.com") { sendEmail(context, "ad13dtu@gmail.com") }
            RowDivider()
            ActionRow("Follow on X", Icons.Filled.AlternateEmail, "@apoorvdarshan") { openUrl(context, "https://x.com/apoorvdarshan") }
            RowDivider()
            ActionRow("Instagram", Icons.Filled.PhotoCamera, "@delts.fit") { openUrl(context, "https://www.instagram.com/delts.fit") }
            RowDivider()
            ActionRow("LinkedIn", Icons.Filled.Business, "Delts") { openUrl(context, "https://www.linkedin.com/company/delts") }
            RowDivider()
            ActionRow("Open Source", Icons.Filled.Code, "GitHub") { openUrl(context, "https://github.com/apoorvdarshan/delts") }
            RowDivider()
            ActionRow("Product Hunt", Icons.AutoMirrored.Filled.Send, "Vote for Delts") { openUrl(context, "https://www.producthunt.com/products/delts") }
        }

        SectionTitle("Spread the Word")
        DeltsCard {
            ActionRow("Rate Delts", Icons.Filled.Star, "Play Store") { openUrl(context, "https://play.google.com/store/apps/details?id=com.apoorvdarshan.delts") }
            RowDivider()
            ActionRow("Share Delts", Icons.Filled.Share, "Play Store link") {
                shareText(context, "Check out Delts — a free exercise library. https://play.google.com/store/apps/details?id=com.apoorvdarshan.delts")
            }
        }

        SectionTitle("Support")
        DeltsCard {
            TipJar(manager)
        }
    }
}

@Composable
private fun TipJar(manager: TipBillingManager) {
    val colors = LocalDeltsColors.current
    val context = LocalContext.current
    val activity = context as? Activity
    val tierIcons = listOf("brand/tip_small.png", "brand/tip_medium.png", "brand/tip_large.png")
    val tierNames = listOf("Small Tip", "Medium Tip", "Large Tip")

    Column(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(11.dp)) {
            Box(Modifier.size(38.dp), contentAlignment = Alignment.CenterStart) {
                Icon(Icons.Filled.Favorite, null, tint = colors.accent, modifier = Modifier.size(21.dp))
            }
            Text("Support Delts", color = colors.charcoal, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        }

        Text(
            "Delts is free forever — tips are optional and unlock nothing.",
            color = colors.mutedText, fontSize = 13.sp
        )

        when {
            manager.showThanks -> ThanksState()
            manager.connecting && manager.products.isEmpty() -> {
                Box(Modifier.fillMaxWidth().heightIn(min = 92.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = colors.accent)
                }
            }
            manager.products.isEmpty() -> {
                Column(Modifier.fillMaxWidth().heightIn(min = 80.dp).padding(vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Tips aren't available yet", color = colors.charcoal, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Text("They go live once the Play Store products are set up.", color = colors.mutedText, fontSize = 12.sp)
                }
            }
            else -> {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    manager.products.forEachIndexed { index, product ->
                        TipTile(
                            iconAsset = tierIcons.getOrElse(index) { tierIcons.last() },
                            name = tierNames.getOrElse(index) { product.name },
                            price = product.oneTimePurchaseOfferDetails?.formattedPrice ?: "",
                            purchasing = manager.purchasingId == product.productId,
                            modifier = Modifier.weight(1f),
                            onClick = { activity?.let { manager.purchase(it, product) } }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun TipTile(
    iconAsset: String,
    name: String,
    price: String,
    purchasing: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val colors = LocalDeltsColors.current
    Column(
        modifier
            .heightIn(min = 92.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(if (purchasing) colors.accent.copy(alpha = 0.16f) else colors.panel.copy(alpha = 0.20f))
            .border(
                if (purchasing) 1.2.dp else 0.6.dp,
                if (purchasing) colors.accent.copy(alpha = 0.78f) else colors.hairline.copy(alpha = 0.26f),
                RoundedCornerShape(16.dp)
            )
            .clickable { onClick() }
            .padding(vertical = 10.dp, horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(7.dp)
    ) {
        Box(Modifier.size(42.dp), contentAlignment = Alignment.Center) {
            if (purchasing) {
                CircularProgressIndicator(color = colors.accent, modifier = Modifier.size(22.dp))
            } else {
                AsyncImage(
                    model = "file:///android_asset/$iconAsset",
                    contentDescription = null,
                    filterQuality = FilterQuality.None,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.size(40.dp)
                )
            }
        }
        Text(name, color = colors.mutedText, fontSize = 11.sp, fontWeight = FontWeight.Black, maxLines = 1)
        Text(price, color = colors.accent, fontSize = 11.sp, fontWeight = FontWeight.Bold, maxLines = 1)
    }
}

@Composable
private fun ThanksState() {
    val colors = LocalDeltsColors.current
    Column(
        Modifier.fillMaxWidth().heightIn(min = 110.dp).padding(vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(Icons.Filled.Favorite, null, tint = colors.accent, modifier = Modifier.size(34.dp))
        Text("Thank you 💚", color = colors.charcoal, fontSize = 17.sp, fontWeight = FontWeight.Bold)
        Text(
            "Your support keeps Delts free for everyone.",
            color = colors.mutedText, fontSize = 12.sp, textAlign = TextAlign.Center
        )
    }
    Spacer(Modifier.size(0.dp))
}

private fun openUrl(context: android.content.Context, url: String) {
    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
}

private fun sendEmail(context: android.content.Context, email: String) {
    runCatching { context.startActivity(Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:$email"))) }
}

private fun shareText(context: android.content.Context, text: String) {
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, text)
    }
    runCatching { context.startActivity(Intent.createChooser(intent, "Share Delts")) }
}
