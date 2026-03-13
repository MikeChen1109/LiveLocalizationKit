//
//  Test.swift
//  LiveLocalizationDemo
//
//  Created by Mike Chen on 2026/3/13.
//

import SwiftUI
import LiveLocalizationUI

struct MarketingLocalizationDemoView: View {
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    featureSection
                    actionSection
                }
                .padding(24)
            }
        }
    }
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LIVE DEMO")
                .font(.caption.weight(.bold))
                .kerning(1.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.08), in: Capsule())

            LiveLocalizedText("Bring multilingual UI to life.")
                .placeholder { phase in
                    Text(phase.displayedText)
                        .redacted(reason: .placeholder)
                }
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(.black)

            LiveLocalizedText("Titles, CTA buttons, and marketing copy can all be translated at runtime for rapid demos.")
                .placeholder { phase in
                    Text(phase.displayedText)
                        .redacted(reason: .placeholder)
                }
                .font(.headline)
                .foregroundStyle(.black.opacity(0.75))
        }
        .padding(24)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color.black.opacity(0.08))
                .padding(20)
        }
    }
    
    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LiveLocalizedText("Demo-ready components")
                .font(.title2.weight(.bold))

            VStack(spacing: 12) {
                demoCard(
                    icon: "textformat.alt",
                    title: "Localized hero title",
                    message: "Use LiveLocalizedText to update visible copy with loading placeholders."
                )
                demoCard(
                    icon: "bolt.badge.clock",
                    title: "Runtime translation",
                    message: "Swap providers or target languages without rebuilding string tables."
                )
                demoCard(
                    icon: "internaldrive",
                    title: "Cache-backed preview",
                    message: "Disk and memory cache stores keep repeated demo runs fast."
                )
            }
        }
    }
    
    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LiveLocalizedText("Localized actions")
                .font(.title2.weight(.bold))

            HStack(spacing: 12) {
                Button {} label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        LiveLocalizedText("Start live captions")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {} label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.rectangle")
                        LiveLocalizedText("Show onboarding")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func demoCard(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 6) {
                LiveLocalizedText(title)
                    .font(.headline)
                LiveLocalizedText(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    MarketingLocalizationDemoView()
}
