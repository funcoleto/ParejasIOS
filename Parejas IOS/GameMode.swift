import SwiftUI

// Define los modos y el contenido para las cartas
enum GameMode: String, CaseIterable, Codable {
    case color = "Colores" // Hasta 40
    case letter = "Letras" // Hasta 25
    case colorAndLetter = "Colores y Letras"
    case shapeAndColor = "Figuras y Colores" // Hasta 40
    
    // Función clave: Genera el conjunto de elementos únicos para el modo.
    func initialUniqueContents() -> [String] {
        switch self {
        case .color:
            // **Estos nombres DEBEN coincidir con los de la extensión Color.from(colorName:)**
            let colors = ["Rojo", "Azul", "Verde", "Amarillo", "Naranja", "Morado", "Rosa", "Cian", "Lima", "Marrón", "Gris", "Negro", "Blanco", "Dorado", "Plata", "Violeta", "Turquesa", "Coral", "Oliva", "Beige"]
            return Array(colors.prefix(20)).map { $0 }
        case .letter:
            // 25 Letras del abecedario español (A-Z, incluyendo Ñ)
            let alphabet = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ".shuffled()
            // Elegimos 12 pares (24 cartas) para hacerlo jugable.
            let selectedLetters = alphabet.prefix(12)
            // Generamos un formato "MAYÚSCULA|minúscula"
            return selectedLetters.map { "\($0.uppercased())|\($0.lowercased())" }
        case .colorAndLetter:
            // Creamos strings que contengan ambos datos, ej: "A|a|Rojo"
            let colors = ["Rojo", "Azul", "Verde", "Amarillo", "Naranja", "Morado", "Rosa", "Cian", "Lima", "Marrón", "Gris", "Negro", "Blanco", "Dorado", "Plata", "Violeta", "Turquesa", "Coral", "Oliva", "Beige"]
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".shuffled()
            return zip(letters, colors).map { "\($0.0.uppercased())|\($0.0.lowercased())|\($0.1)" } // Genera hasta 20 pares (40 cartas)
        case .shapeAndColor:
            // Define un set de figuras (SFSymbols) y colores.
            let shapes = ["star.fill", "heart.fill", "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "hexagon.fill", "octagon.fill", "shield.fill", "flag.fill", "bell.fill", "tag.fill", "bolt.fill", "camera.fill", "message.fill", "phone.fill", "sun.max.fill", "moon.fill", "cloud.fill", "flame.fill"]
            let colors = ["Rojo", "Azul", "Verde", "Amarillo", "Naranja", "Morado", "Rosa", "Cian", "Lima", "Marrón", "Gris", "Negro", "Blanco", "Dorado", "Plata", "Violeta", "Turquesa", "Coral", "Oliva", "Beige"]
            
            // Generamos combinaciones únicas (Figura|Color) para 20 pares (40 cartas).
            return zip(shapes, colors).map { "\($0.0)|\($0.1)" }
        }
    }
}
