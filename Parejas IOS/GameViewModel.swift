import Foundation
import SwiftUI



// Lógica del juego: estado, tiempo, volteos y emparejamiento.
class GameViewModel: ObservableObject {
    @Published private(set) var cards: [Card] = []
    @Published private(set) var flipCount = 0
    @Published private(set) var timeElapsed: Double = 0.0
    @Published private(set) var isGameOver = false
    
    let currentMode: GameMode
    private var timer: Timer?
    private var lastFlipTime: Date?
    
    // Almacena los identificadores de las cartas que están boca arriba.
    private var faceUpCardIDs: [UUID] = []
    
    let settings: SettingsManager
    // Función clave 1: Inicialización y configuración del tablero.
    init(mode: GameMode, settings: SettingsManager) {
        self.currentMode = mode
        self.settings = settings
        // Se elimina la llamada a startGame() de aquí para que se controle desde la vista.
    }
    
    // Función clave 2: Reinicia o inicia el juego.
    private func numberOfCardsToGenerate() -> Int {
        // Usamos una extensión de SwiftUI para determinar el tipo de dispositivo
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        
        // iPad: hasta 40 cartas (20 pares). iPhone: hasta 20 cartas (10 pares).
        let maxPairs = settings.numberOfPairs
        
        // Asegúrate de que no pides más contenido del disponible
        let availableContents = currentMode.initialUniqueContents().count
        
        // Devuelve el número de pares que se usarán (multiplicado por 2 para el total de cartas)
        return min(maxPairs, availableContents) * 2
    }
    
    // Función clave 2: Actualización de la función startGame()
    func startGame() { // Asume que GameViewModel hereda de NSObject si usas @objc, sino simplemente usa func
        let totalCards = numberOfCardsToGenerate()
        let totalPairs = totalCards / 2
        
        // 1. Obtener los contenidos (solo los necesarios)
        let uniqueContents = Array(currentMode.initialUniqueContents().prefix(totalPairs))
        
        // 2. Duplicar y mezclar
        let pairs = (uniqueContents + uniqueContents).shuffled()
        
        // 3. Crear las cartas
        cards = pairs.map { content in
            Card(content: content, mode: currentMode)
        }
        
        // Resetear el estado... (el resto de tu lógica de reset)
        flipCount = 0
        timeElapsed = 0.0
        isGameOver = false
        faceUpCardIDs = []
        
        startTimer()
    }
    
    // Función clave 3: Maneja la lógica de voltear una carta.
    func choose(card: Card) {
        guard let chosenIndex = cards.firstIndex(where: { $0.id == card.id }),
              !cards[chosenIndex].isFaceUp,
              !cards[chosenIndex].isMatched,
              faceUpCardIDs.count < 2,
              !isGameOver
        else { return }
        
        // 1. Voltear la carta
        cards[chosenIndex].isFaceUp = true
        faceUpCardIDs.append(card.id)
        flipCount += 1
        
        // 2. Comprobar si hay un par para comparar
        if faceUpCardIDs.count == 2 {
            // Retraso para que el usuario pueda ver la segunda carta
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                self?.checkForMatch()
            }
        }
    }
    
    // Función clave 4: Lógica de emparejamiento.
    private func checkForMatch() {
        guard let firstID = faceUpCardIDs.first,
              let secondID = faceUpCardIDs.last,
              let index1 = cards.firstIndex(where: { $0.id == firstID }),
              let index2 = cards.firstIndex(where: { $0.id == secondID })
        else {
            faceUpCardIDs = []
            return
        }
        
        // Comprobar si son el mismo contenido
        if cards[index1] == cards[index2] {
            // Coinciden: Marcarlas como emparejadas
            cards[index1].isMatched = true
            cards[index2].isMatched = true
        } else {
            // No coinciden: Volverlas a ocultar
            cards[index1].isFaceUp = false
            cards[index2].isFaceUp = false
        }
        
        faceUpCardIDs = [] // Limpiar las cartas boca arriba
        
        // 3. Comprobar fin del juego
        if cards.allSatisfy({ $0.isMatched }) {
            stopTimer()
            isGameOver = true
        }
    }
    
    // Función clave 5: Inicia el temporizador.
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.timeElapsed += 0.1
        }
    }
    
    // Función clave 6: Detiene el temporizador.
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}



extension GameViewModel {
    
    // Función clave 1: Determina el número de cartas basado en el dispositivo.
    
}
