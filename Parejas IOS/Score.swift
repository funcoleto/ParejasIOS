import Foundation

// Define los modos y el contenido para las cartas
enum GameMode: String, CaseIterable, Codable {
    case color = "Colores"
    case letter = "Letras"
    case colorAndLetter = "Colores y Letras"
    case shapeAndColor = "Figuras y Colores"
    case matematicas = "Matemáticas"
    case puzzle = "Puzzle"

    // Función clave: Genera el conjunto de elementos únicos para el modo.
    func initialUniqueContents() -> [String] {
        switch self {
        case .color:
            let colors = ["Rojo", "Azul", "Verde", "Amarillo", "Naranja", "Morado", "Rosa", "Cian", "Lima", "Marrón", "Gris", "Negro", "Blanco", "Dorado", "Plata", "Violeta", "Turquesa", "Coral", "Oliva", "Beige", "Índigo", "Magenta", "Salmón", "Acero"]
            return colors
        case .letter:
            let alphabet = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ".shuffled()
            return alphabet.map { "\($0.uppercased())|\($0.lowercased())" }
        case .colorAndLetter:
            let colors = ["Rojo", "Azul", "Verde", "Amarillo", "Naranja", "Morado", "Rosa", "Cian", "Lima", "Marrón", "Gris", "Negro", "Blanco", "Dorado", "Plata", "Violeta", "Turquesa", "Coral", "Oliva", "Beige", "Índigo", "Magenta", "Salmón", "Acero"]
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".shuffled()
            return zip(letters, colors).map { "\($0.0.uppercased())|\($0.0.lowercased())|\($0.1)" }
        case .shapeAndColor:
            let shapes = ["star.fill", "heart.fill", "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "hexagon.fill", "octagon.fill", "shield.fill", "flag.fill", "bell.fill", "tag.fill", "bolt.fill", "camera.fill", "message.fill", "phone.fill", "sun.max.fill", "moon.fill", "cloud.fill", "flame.fill", "leaf.fill", "airplane", "car.fill", "bus.fill"]
            let colors = ["Rojo", "Azul", "Verde", "Amarillo", "Naranja", "Morado", "Rosa", "Cian", "Lima", "Marrón", "Gris", "Negro", "Blanco", "Dorado", "Plata", "Violeta", "Turquesa", "Coral", "Oliva", "Beige", "Índigo", "Magenta", "Salmón", "Acero"]
            return zip(shapes, colors).map { "\($0.0)|\($0.1)" }
        case .matematicas, .puzzle:
            return []
        }
    }
}

// La estructura para guardar los datos del ranking.
struct Score: Identifiable, Codable, Equatable {
    var id = UUID()
    var playerName: String
    var timeInSeconds: Double
    var mode: GameMode
    var numberOfPairs: Int
    var mathScore: Int? // Puntuación para el modo matemáticas
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
