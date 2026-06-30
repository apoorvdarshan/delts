package com.apoorvdarshan.delts.billing

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ConsumeParams
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams

/**
 * Google Play Billing tip jar (the Android analog of the iOS StoreKit `TipStore`).
 * Three consumable one-time products; tipping unlocks nothing. Until the products
 * exist in the Play Console (analogous to App Store Connect IAPs), the query
 * returns empty and the UI shows the "unavailable" state — same as iOS today.
 */
class TipBillingManager(context: Context) {

    val productIds = listOf(
        "com.apoorvdarshan.delts.tip.small",
        "com.apoorvdarshan.delts.tip.medium",
        "com.apoorvdarshan.delts.tip.large"
    )

    var products by mutableStateOf<List<ProductDetails>>(emptyList())
        private set
    var connecting by mutableStateOf(true)
        private set
    var showThanks by mutableStateOf(false)
    var errorMessage by mutableStateOf<String?>(null)
    var purchasingId by mutableStateOf<String?>(null)
        private set

    private val billingClient: BillingClient = BillingClient.newBuilder(context)
        .setListener(::onPurchasesUpdated)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build()
        )
        .build()

    fun connect() {
        connecting = true
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryProducts()
                } else {
                    connecting = false
                }
            }

            override fun onBillingServiceDisconnected() {
                connecting = false
            }
        })
    }

    private fun queryProducts() {
        val productList = productIds.map { id ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(id)
                .setProductType(BillingClient.ProductType.INAPP)
                .build()
        }
        val params = QueryProductDetailsParams.newBuilder().setProductList(productList).build()
        billingClient.queryProductDetailsAsync(params) { _, list ->
            products = list.sortedBy { it.oneTimePurchaseOfferDetails?.priceAmountMicros ?: 0L }
            connecting = false
        }
    }

    fun retry() {
        errorMessage = null
        connect()
    }

    fun purchase(activity: Activity, product: ProductDetails) {
        errorMessage = null
        purchasingId = product.productId
        val productParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(product)
            .build()
        val flowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(productParams))
            .build()
        billingClient.launchBillingFlow(activity, flowParams)
    }

    private fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        purchasingId = null
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
                        // Consumable tip: consume so it can be given again; unlocks nothing.
                        val consumeParams = ConsumeParams.newBuilder()
                            .setPurchaseToken(purchase.purchaseToken)
                            .build()
                        billingClient.consumeAsync(consumeParams) { _, _ -> }
                        showThanks = true
                    }
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> { /* silent */ }
            else -> { errorMessage = result.debugMessage.ifBlank { "The tip couldn't be completed. Please try again." } }
        }
    }

    fun release() {
        billingClient.endConnection()
    }
}
