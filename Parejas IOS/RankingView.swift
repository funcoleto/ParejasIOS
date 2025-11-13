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
                    // Posición: Ancho fijo pequeño
                    Text("Pos").bold().frame(width: 30, alignment: .leading)
                    
                    // Nombre: Ancho flexible máximo
                    Text("Nombre").bold()
                    
                    Spacer() // Empuja el tiempo a la derecha
                    
                    // Tiempo: Ancho ligeramente más ancho para MM:SS
                    Text("Tiempo").bold().frame(width: 60, alignment: .trailing)
                }
                // Importante: forzar al HStack a ocupar todo el ancho de la List
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
                            // Posición
                            Text("\(index + 1)").frame(width: 30, alignment: .leading)
                            
                            // Nombre
                            Text(score.playerName)
                            
                            Spacer()
                            
                            // Tiempo
                            Text(score.displayTime).frame(width: 60, alignment: .trailing)
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
