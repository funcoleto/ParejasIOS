import SwiftUI
import UIKit // Necesario para la lógica de adaptabilidad (UIDevice.current)

struct GameView: View {
    // Usamos @ObservedObject porque el ViewModel se inicializa en ContentView y se pasa.
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var rankingManager: RankingManager
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingGameOver = false
    @State private var finalTime: Double = 0.0
    
    // Propiedad calculada: Determina el número de columnas para la cuadrícula
    private var columns: [GridItem] {
        let totalCards = viewModel.cards.count
        guard totalCards > 0 else { return [] }

        // Algoritmo para determinar el número de columnas ideal
        let numColumns: Int
        if totalCards <= 12 {
            numColumns = 3
        } else if totalCards <= 20 {
            numColumns = 4
        } else if totalCards <= 30 {
            numColumns = 5
        } else if totalCards <= 42 {
            numColumns = 6
        } else {
            numColumns = 7
        }
        
        // Crea las columnas flexibles para que se ajusten al ancho disponible.
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: numColumns)
    }
    
    var body: some View {
        VStack {
            // Marcadores de Estado
            HStack {
                Text("Modo: **\(viewModel.currentMode.rawValue)**")
                    .lineLimit(1)
                
                Spacer()
                
                // Mostrar Tiempo y Volteos en vertical para ahorrar espacio en iPhone
                VStack(alignment: .trailing) {
                    Text("Tiempo: **\(Score(playerName: "", timeInSeconds: viewModel.timeElapsed, mode: .color, numberOfPairs: viewModel.cards.count / 2).displayTime)**")
                    Text("Volteos: **\(viewModel.flipCount)**")
                }
            }
            .font(.headline)
            .padding([.horizontal, .top])
            
            // Cuadrícula de Cartas con Columnas Dinámicas
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.cards) { card in
                    CardView(viewModel: viewModel, card: card, settings: viewModel.settings)
                        // AspectRatio para mantener la forma vertical de la carta
                        .aspectRatio(2/3, contentMode: .fit)
                        .opacity(card.isMatched && !viewModel.settings.showMatchedCards ? 0 : 1) // Oculta las cartas emparejadas
                        .onTapGesture {
                            viewModel.choose(card: card)
                        }
                }
            }
            .padding()
            
            Spacer() // Empuja el contenido hacia arriba si hay espacio sobrante
        }
        // Clave para evitar errores de Layout: La vista ocupa todo el espacio disponible
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}
