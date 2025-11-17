import SwiftUI

// Muestra la lista de Top 10 para cada modo.
struct RankingView: View {
    @ObservedObject var rankingManager: RankingManager
    // Asegúrate de que selectedMode está inicializado con un caso válido.
    @State private var selectedMode: GameMode = .color
    
    var body: some View {
        VStack {
            // Selector para elegir el modo de juego
            Picker("Modo", selection: $selectedMode) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top]) // Menos padding arriba
            
            List {
                let topScores = rankingManager.getTop10(for: selectedMode)
                
                // --- Encabezado del Ranking ---
                HStack {
                    Text("Pos").bold().frame(width: 30, alignment: .leading)
                    Text("Nombre").bold()
                    Spacer()
                    
                    if selectedMode == .matematicas {
                        Text("Aciertos").bold().frame(width: 70, alignment: .trailing)
                        Text("Fallos").bold().frame(width: 70, alignment: .trailing)
                    } else {
                        Text("Tiempo").bold().frame(width: 60, alignment: .trailing)
                        Text("Parejas").bold().frame(width: 70, alignment: .trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if topScores.isEmpty {
                    Text("Aún no hay puntuaciones en este modo. ¡Sé el primero!")
                        .foregroundColor(.gray)
                        .padding(.vertical, 10)
                } else {
                    // --- Lista de Puntuaciones ---
                    ForEach(topScores.indices, id: \.self) { index in
                        let score = topScores[index]
                        HStack {
                            Text("\(index + 1)").frame(width: 30, alignment: .leading)
                            Text(score.playerName)
                            Spacer()
                            
                            if selectedMode == .matematicas {
                                let aciertos = score.mathScore ?? 0
                                let fallos = score.totalItems - aciertos
                                Text("\(aciertos)").frame(width: 70, alignment: .trailing)
                                Text("\(fallos)").frame(width: 70, alignment: .trailing)
                            } else {
                                Text(score.displayTime).frame(width: 60, alignment: .trailing)
                                Text("\(score.totalItems)").frame(width: 70, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            // Importante: Eliminar cualquier padding extra de la List que pueda crear conflicto
            .listStyle(.plain)
        }
        .navigationTitle("🏆 Top 10 Ranking")
    }
}
