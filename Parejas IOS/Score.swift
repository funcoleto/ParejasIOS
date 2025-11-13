import Foundation

// La estructura para guardar los datos del ranking.
struct Score: Identifiable, Codable {
    let id = UUID()
    let playerName: String
    let timeInSeconds: Double // El valor principal para ordenar
    let mode: GameMode
    let date = Date()
    
    // Función para mostrar el tiempo en formato MM:SS
    var displayTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: timeInSeconds) ?? "00:00"
    }
}
