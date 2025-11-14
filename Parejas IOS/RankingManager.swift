import Foundation
import SwiftUI

/// Gestiona el ranking de puntuaciones de todos los modos de juego.
///
/// Esta clase es responsable de:
/// - Cargar las puntuaciones guardadas desde `UserDefaults`.
/// - Guardar nuevas puntuaciones.
/// - Mantener el ranking limitado a las 10 mejores puntuaciones por cada modo de juego.
/// - Ordenar las puntuaciones según las reglas de cada modo (tiempo ascendente o aciertos descendente).
class RankingManager: ObservableObject {
    /// Contiene todas las puntuaciones de todos los modos de juego, hasta un máximo de 10 por modo.
    @Published var allScores: [Score] = []
    private let key = "MemoryGameTopScores"
    
    init() {
        loadScores()
    }
    
    /// Carga las puntuaciones desde `UserDefaults` al iniciar la aplicación.
    /// Si no hay puntuaciones guardadas, inicializa la lista como vacía.
    func loadScores() {
        if let savedData = UserDefaults.standard.data(forKey: key),
           let decodedScores = try? JSONDecoder().decode([Score].self, from: savedData) {
            self.allScores = decodedScores
        } else {
            self.allScores = []
        }
    }
    
    /// Añade una nueva puntuación, recalcula el ranking para el modo de juego correspondiente y guarda la lista actualizada.
    ///
    /// - Parameter newScore: La nueva puntuación que se va a añadir.
    func saveScore(newScore: Score) {
        allScores.append(newScore)
        
        var updatedScores: [Score] = []
        for mode in GameMode.allCases {
            var modeScores = allScores.filter { $0.mode == mode }

            if mode == .matematicas {
                modeScores.sort { $0.mathScore ?? 0 > $1.mathScore ?? 0 } // Ordenar por puntuación descendente
            } else {
                modeScores.sort { $0.timeInSeconds < $1.timeInSeconds } // Ordenar por tiempo ascendente
            }

            let top10 = modeScores.prefix(10)
            updatedScores.append(contentsOf: top10)
        }
        
        self.allScores = updatedScores
        
        if let encoded = try? JSONEncoder().encode(self.allScores) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    /// Devuelve las 10 mejores puntuaciones para un modo de juego específico.
    ///
    /// - Parameter mode: El modo de juego para el cual se quiere obtener el ranking.
    /// - Returns: Un array con las 10 mejores puntuaciones, ordenadas según las reglas del modo.
    func getTop10(for mode: GameMode) -> [Score] {
        let filteredScores = allScores.filter { $0.mode == mode }

        if mode == .matematicas {
            return filteredScores
                .sorted { $0.mathScore ?? 0 > $1.mathScore ?? 0 } // Puntuación descendente
                .prefix(10)
                .map { $0 }
        } else {
            return filteredScores
                .sorted { $0.timeInSeconds < $1.timeInSeconds } // Tiempo ascendente
                .prefix(10)
                .map { $0 }
        }
    }
}
