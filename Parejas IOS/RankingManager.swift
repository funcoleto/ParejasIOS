import Foundation
import SwiftUI

// Gestiona el Top 10 del ranking con persistencia (UserDefaults).
class RankingManager: ObservableObject {
    @Published var allScores: [Score] = []
    private let key = "MemoryGameTopScores"
    
    init() {
        loadScores()
    }
    
    // Función clave 1: Carga las puntuaciones guardadas.
    func loadScores() {
        if let savedData = UserDefaults.standard.data(forKey: key),
           let decodedScores = try? JSONDecoder().decode([Score].self, from: savedData) {
            self.allScores = decodedScores
        } else {
            self.allScores = []
        }
    }
    
    // Función clave 2: Añade una nueva puntuación, la ordena y la guarda.
    func saveScore(newScore: Score) {
        // 1. Añadir la nueva puntuación
        allScores.append(newScore)
        
        // 2. Filtrar y ordenar el Top 10 por cada modo
        var updatedScores: [Score] = []
        for mode in GameMode.allCases {
            let top10 = allScores
                .filter { $0.mode == mode }
                .sorted { $0.timeInSeconds < $1.timeInSeconds } // Ordenar por tiempo ascendente
                .prefix(10)
            updatedScores.append(contentsOf: top10)
        }
        
        self.allScores = updatedScores
        
        // 3. Guardar el array completo
        if let encoded = try? JSONEncoder().encode(self.allScores) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    // Función clave 3: Obtiene el Top 10 para un modo específico (usada por RankingView)
    func getTop10(for mode: GameMode) -> [Score] {
        return allScores
            .filter { $0.mode == mode }
            .sorted { $0.timeInSeconds < $1.timeInSeconds }
            .prefix(10)
            .map { $0 }
    }
}
