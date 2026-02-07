//
//  ScanAnimationView.swift
//  BluetoothLANScan
//
//  Created by Арсений on 07.02.2026.
//

import SwiftUI
import Lottie

struct LottieAnimationView: UIViewRepresentable {
    var name: String
    var loopMode: LottieLoopMode = .loop
    var animationSpeed: CGFloat = 1.0
    
    func makeUIView(context: Context) -> Lottie.LottieAnimationView {
        let animationView = Lottie.LottieAnimationView()
        
        if let animation = LottieAnimation.named(name) {
            animationView.animation = animation
        }
        
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.contentMode = .scaleAspectFit
        
        animationView.play()
        
        return animationView
    }
    
    func updateUIView(_ uiView: Lottie.LottieAnimationView, context: Context) {
        if !uiView.isAnimationPlaying {
            uiView.play()
        }
    }
}

struct AdaptiveScanOverlay: View {
    let isScanning: Bool
    
    var body: some View {
        if isScanning {
            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(false)
                .overlay(
                    VStack {
                        VStack(spacing: 12) {
                            if Bundle.main.path(forResource: "scan", ofType: "json") != nil {
                                LottieAnimationView(name: "scan", loopMode: .loop, animationSpeed: 1.5)
                                    .frame(width: 60, height: 60)
                            }
                            
                            Text("Сканирование активено")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                        
                        Spacer()
                    }
                    .padding(.top, safeAreaTop + 10)
                    .allowsHitTesting(false)
                )
                .ignoresSafeArea()
        }
    }
    
    private var safeAreaTop: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
    }
}
