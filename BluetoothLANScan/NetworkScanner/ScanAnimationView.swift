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

struct ScanAnimationOverlay: View {
    let isScanning: Bool
    
    var body: some View {
        if isScanning {
            ZStack {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if Bundle.main.path(forResource: "scan", ofType: "json") != nil {
                        LottieAnimationView(name: "scan", loopMode: .loop, animationSpeed: 1.5)
                            .frame(width: 150, height: 150)
                    } else {
                        
                    }
                    
                    VStack(spacing: 8) {
                        Text("Идет сканирование...")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Пожалуйста, подождите")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6).opacity(0.95))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(40)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: isScanning)
        }
    }
}
