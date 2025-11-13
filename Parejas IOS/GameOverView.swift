import SwiftUI

// Se muestra cuando el juego termina para capturar el nombre y guardar el ranking.
@available(iOS 15.0, *)
struct GameOverView: View {
    let mode: GameMode
    let score: Double
    @ObservedObject var rankingManager: RankingManager
    let onPlayAgain: () -> Void
    let onMainMenu: () -> Void
    
    @State private var playerName: String = ""
    @State private var scoreSaved: Bool = false

    
    @available(iOS 15.0, *)
    var body: some View {
        VStack(spacing: 20) {
            Text("¡Juego Terminado! 🥳")
                .font(.largeTitle).bold()
            
            Text("Modo: \(mode.rawValue)")
                .font(.title2)
            
            Text("Tu Tiempo: **\(Score(playerName: "", timeInSeconds: score, mode: mode).displayTime)**")
                .font(.title2)
            
            if !scoreSaved {
                TextField("Ingresa tu Nombre", text: $playerName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)
                
                // Función clave: Guardar la puntuación en el RankingManager
                if #available(iOS 15.0, *) {
                    Button("Guardar Puntuación") {
                        guard !playerName.isEmpty else { return }
                        let newScore = Score(playerName: playerName, timeInSeconds: score, mode: mode)
                        rankingManager.saveScore(newScore: newScore)
                        scoreSaved = true
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    // Fallback on earlier versions
                }
            } else {
                Text("¡Puntuación guardada con éxito!")
                    .foregroundColor(.green)
            }
            
            Button("Jugar de Nuevo") {
                onPlayAgain()
            }
            .buttonStyle(.bordered)

            Button("Volver al Menú Principal") {
                onMainMenu()
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
    }
}
