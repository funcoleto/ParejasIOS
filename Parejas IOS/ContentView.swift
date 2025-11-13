// ContentView.swift
import SwiftUI
// Si GameViewModel, GameView, o GameMode están en un módulo o archivo separado,
// generalmente no necesitas importaciones adicionales aquí,
// pero asegúrate de que GameView, GameViewModel, y GameMode sean accesibles.



// ContentView.swift
struct ContentView: View {
    @StateObject var rankingManager = RankingManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Juego de Parejas 🧠")
                    .font(.largeTitle).bold()
                
                Divider()
                
                ForEach(GameMode.allCases, id: \.self) { mode in
                    NavigationLink(destination:
                        // Envuelve el destino en una ZStack. Esto es un truco conocido de SwiftUI.
                        ZStack {
                            GameView(viewModel: GameViewModel(mode: mode), rankingManager: rankingManager)
                        }
                    ) {
                        Text("Modo \(mode.rawValue)")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Divider()
                
                NavigationLink(destination: RankingView(rankingManager: rankingManager)) {
                    Text("🏆 Ver Top 10 Ranking")
                        .font(.title2).bold()
                        .padding()
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationTitle("Menú Principal")
        }
    }
}
