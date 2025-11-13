import Foundation

// La estructura de la carta, cómo se representa en el juego.
struct Card: Identifiable, Equatable {
    let id = UUID()
    let content: String // El contenido visual (color, letra, nombre de figura SF)
    var isFaceUp = false // Está boca arriba
    var isMatched = false // Ya está emparejada y fuera del juego
    let mode: GameMode // Para diferenciar cómo se muestra el contenido
    
    // Usada por el ViewModel para saber si dos cartas son un par
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.content == rhs.content
    }
}
