import SwiftUI
import UIKit // Necesario para la lógica de adaptabilidad (UIDevice.current)

struct GameView: View {
    // Usamos @ObservedObject porque el ViewModel se inicializa en ContentView y se pasa.
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var rankingManager: RankingManager
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingGameOver = false
    @State private var finalTime: Double = 0.0
    
    var body: some View {
        VStack {
            // Marcadores de Estado
            HStack {
                Text("Modo: **\(viewModel.currentMode.rawValue)**")
                    .lineLimit(1)
                
                Spacer()
                
                // Mostrar Tiempo y Volteos en vertical para ahorrar espacio en iPhone
                VStack(alignment: .trailing) {
                    Text("Tiempo: **\(Score(playerName: "", timeInSeconds: viewModel.timeElapsed, mode: .color, totalItems: viewModel.cards.count / 2, puzzleGridSize: nil).displayTime)**")
                    Text("Volteos: **\(viewModel.flipCount)**")
                }
            }
            .font(.headline)
            .padding([.horizontal, .top])
            
            // Geometría para adaptar la cuadrícula al espacio disponible
            GeometryReader { geometry in
                let gridColumns = calculateGridColumns(for: geometry.size)

                // Cuadrícula de Cartas con Columnas Dinámicas
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(viewModel.cards) { card in
                        CardView(viewModel: viewModel, card: card, settings: viewModel.settings)
                            // AspectRatio para mantener la forma vertical de la carta
                            .aspectRatio(2/3, contentMode: .fit)
                            .opacity(card.isMatched && !viewModel.settings.showMatchedCards ? 0 : 1)
                            .onTapGesture {
                                viewModel.choose(card: card)
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Jugar")
        .navigationBarTitleDisplayMode(.inline) // Estilo compacto para reducir conflictos
        
        // Detector de fin de juego
        .onChange(of: viewModel.isGameOver) { isOver in
            if isOver {
                finalTime = viewModel.timeElapsed
                showingGameOver = true
            }
        }
        
        // Pantalla de fin de juego (modal)
        .sheet(isPresented: $showingGameOver) {
            GameOverView(
                viewModel: viewModel,
                mode: viewModel.currentMode,
                score: finalTime,
                rankingManager: rankingManager,
                onPlayAgain: {
                    // Lógica para reiniciar el juego y cerrar el modal
                    viewModel.startGame()
                    showingGameOver = false
                },
                onMainMenu: {
                    showingGameOver = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            viewModel.startGame()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    // Función para calcular el número óptimo de columnas
    private func calculateGridColumns(for size: CGSize) -> [GridItem] {
        let totalCards = viewModel.cards.count
        guard totalCards > 0 else { return [] }

        let cardAspectRatio: CGFloat = 2/3
        let spacing: CGFloat = 10 // Espaciado horizontal y vertical

        var bestColumnCount = 1
        var maxCardHeight: CGFloat = 0

        // Itera para encontrar el número de columnas que maximiza el tamaño de la carta
        // sin que la altura total de la cuadrícula exceda la altura disponible.
        for columnCount in 2...10 { // Prueba con un número razonable de columnas
            let totalSpacingWidth = spacing * CGFloat(columnCount - 1)
            let cardWidth = (size.width - totalSpacingWidth - 20) / CGFloat(columnCount) // 20 para padding
            let cardHeight = cardWidth / cardAspectRatio

            let rowCount = ceil(CGFloat(totalCards) / CGFloat(columnCount))
            let totalGridHeight = (rowCount * cardHeight) + (spacing * (rowCount - 1))

            if totalGridHeight <= size.height && cardHeight > maxCardHeight {
                maxCardHeight = cardHeight
                bestColumnCount = columnCount
            }
        }

        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: bestColumnCount)
    }
}
