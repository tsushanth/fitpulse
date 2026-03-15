//
//  PaywallView.swift
//  FitPulse
//
//  Premium subscription paywall
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreKitManager.self) private var storeKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product? = nil
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // Header
                    headerSection

                    // Features
                    featuresSection

                    // Products
                    productsSection

                    // CTA
                    ctaSection

                    // Legal
                    legalSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.track(.paywallViewed)
            if let firstProduct = storeKitManager.subscriptions.first(where: { $0.isPopular }) {
                selectedProduct = firstProduct
            } else {
                selectedProduct = storeKitManager.subscriptions.last
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color.fitPulseGreen, Color.fitPulseBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)

            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)

                Text("FitPulse Premium")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Unlock your full fitness potential")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Premium Features")
                    .font(.title2.bold())
                    .padding(.bottom, 4)

                ForEach(premiumFeatures, id: \.title) { feature in
                    PremiumFeatureRow(feature: feature)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var productsSection: some View {
        VStack(spacing: 12) {
            if storeKitManager.isLoading {
                ProgressView("Loading plans...")
                    .padding()
            } else if storeKitManager.subscriptions.isEmpty {
                Text("No plans available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(storeKitManager.subscriptions) { product in
                    ProductOptionView(
                        product: product,
                        isSelected: selectedProduct?.id == product.id
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
        .padding()
    }

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                purchase()
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(ctaTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.fitPulseGreen)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(isPurchasing || selectedProduct == nil)

            Button("Restore Purchases") {
                Task {
                    await storeKitManager.restorePurchases()
                    if storeKitManager.isPremium {
                        dismiss()
                    }
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Subscriptions auto-renew unless cancelled. Cancel anytime in App Store settings.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Privacy Policy") {
                    if let url = URL(string: "https://fitpulse.app/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Terms of Use") {
                    if let url = URL(string: "https://fitpulse.app/terms") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .padding(.bottom, 32)
    }

    private var ctaTitle: String {
        guard let product = selectedProduct else { return "Get Premium" }
        if product.subscription?.subscriptionPeriod.unit == .year {
            if let introOffer = product.subscription?.introductoryOffer {
                return "Try Free for \(introOffer.period.value) \(introOffer.period.unit.description)"
            }
        }
        return "Subscribe for \(product.displayPrice)/\(product.periodLabel)"
    }

    private func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        AnalyticsService.shared.track(.purchaseStarted(productID: product.id))

        Task {
            do {
                _ = try await storeKitManager.purchase(product)
                AnalyticsService.shared.track(.purchaseCompleted(productID: product.id))
                isPurchasing = false
                dismiss()
            } catch StoreKitError.userCancelled {
                isPurchasing = false
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
                AnalyticsService.shared.track(.purchaseFailed)
            }
        }
    }

    private var premiumFeatures: [PremiumFeature] {
        [
            PremiumFeature(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Analytics",
                description: "Detailed charts and trend analysis",
                color: .fitPulseGreen
            ),
            PremiumFeature(
                icon: "clock.arrow.circlepath",
                title: "Full History",
                description: "Access all past workouts and metrics",
                color: .fitPulseBlue
            ),
            PremiumFeature(
                icon: "square.and.arrow.up",
                title: "Export Data",
                description: "Export to CSV, PDF, and more",
                color: .fitPulseOrange
            ),
            PremiumFeature(
                icon: "target",
                title: "Custom Goals",
                description: "Personalized daily and weekly targets",
                color: .fitPulsePurple
            ),
            PremiumFeature(
                icon: "moon.stars.fill",
                title: "Sleep Analysis",
                description: "Detailed sleep stage breakdown",
                color: .fitPulsePurple
            ),
            PremiumFeature(
                icon: "bell.badge.fill",
                title: "Smart Reminders",
                description: "Intelligent activity and stand alerts",
                color: .fitPulseRed
            ),
        ]
    }
}

// MARK: - Subviews

struct PremiumFeatureRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(.title3)
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline.bold())
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundColor(.fitPulseGreen)
        }
    }
}

struct ProductOptionView: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if product.isPopular {
                            Text("BEST VALUE")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.fitPulseOrange)
                                .cornerRadius(4)
                        }
                    }

                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                    Text(product.periodLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.fitPulseGreen : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.fitPulseGreen)
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(isSelected ? Color.fitPulseGreen.opacity(0.08) : Color.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.fitPulseGreen : Color.clear, lineWidth: 2)
            )
            .cornerRadius(16)
        }
    }
}

struct PremiumFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Extension
extension Product.SubscriptionPeriod.Unit {
    var description: String {
        switch self {
        case .day: return "days"
        case .week: return "weeks"
        case .month: return "months"
        case .year: return "years"
        @unknown default: return "periods"
        }
    }
}
