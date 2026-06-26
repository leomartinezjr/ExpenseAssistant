import SwiftUI

struct LiquidGlassBackgroundView: View {
    @State private var animateBlob1 = false
    @State private var animateBlob2 = false
    @State private var animateBlob3 = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background base escuro/neutro
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Bolhas coloridas que se movem de forma fluida
                ZStack {
                    // Blob 1: Roxo
                    Circle()
                        .fill(Color.purple.opacity(0.45))
                        .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                        .offset(
                            x: animateBlob1 ? geometry.size.width * 0.2 : -geometry.size.width * 0.2,
                            y: animateBlob1 ? geometry.size.height * 0.15 : -geometry.size.height * 0.1
                        )
                    
                    // Blob 2: Azul
                    Circle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                        .offset(
                            x: animateBlob2 ? -geometry.size.width * 0.25 : geometry.size.width * 0.15,
                            y: animateBlob2 ? -geometry.size.height * 0.1 : geometry.size.height * 0.2
                        )
                    
                    // Blob 3: Rosa/Magenta
                    Circle()
                        .fill(Color.pink.opacity(0.35))
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(
                            x: animateBlob3 ? geometry.size.width * 0.15 : -geometry.size.width * 0.3,
                            y: animateBlob3 ? -geometry.size.height * 0.2 : geometry.size.height * 0.1
                        )
                }
                .blur(radius: 60)
                
                // Camada superior de vidro fosco (Refração)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                // Overlay de brilho sutil (Efeito Specular)
                LinearGradient(
                    colors: [.white.opacity(0.08), .clear, .black.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 18)
                    .repeatForever(autoreverses: true)
                ) {
                    animateBlob1.toggle()
                }
                
                withAnimation(
                    .linear(duration: 22)
                    .repeatForever(autoreverses: true)
                ) {
                    animateBlob2.toggle()
                }
                
                withAnimation(
                    .linear(duration: 15)
                    .repeatForever(autoreverses: true)
                ) {
                    animateBlob3.toggle()
                }
            }
        }
    }
}

#Preview {
    LiquidGlassBackgroundView()
}
