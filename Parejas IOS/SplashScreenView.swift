import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    // Callback to notify when splash is finished
    var onFinished: () -> Void
    
    var body: some View {
        if isActive {
            // This part shouldn't be reached if the parent switches views, 
            // but we keep it for logic consistency or if we want to fade out this view itself.
            Color.clear.onAppear {
                onFinished()
            }
        } else {
            VStack {
                VStack {
                    Image("WelcomeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                    
                    Text("Parejas IOS")
                        .font(Font.custom("Baskerville-Bold", size: 26))
                        .foregroundColor(.black.opacity(0.80))
                        .padding(.top, 20)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.1
                        self.opacity = 1.00
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white) // Or match your app's theme
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView(onFinished: {})
    }
}
