import Foundation

// La estructura para guardar los datos del ranking.
struct Score: Identifiable, Codable, Equatable {
    var id = UUID()
    var playerName: String
    var timeInSeconds: Double
    var mode: GameMode
    var totalItems: Int // Nº de parejas, operaciones, etc.
    var mathScore: Int? // Aciertos en el modo matemáticas
    var puzzleGridSize: String? // Tamaño de la cuadrícula para el puzzle
    var date = Date()
    
    // Formatea el tiempo para visualización (ej: 01:30.5)
    var displayTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: timeInSeconds) ?? "00:00"
    }
}
