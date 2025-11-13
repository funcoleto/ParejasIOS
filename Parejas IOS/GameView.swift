import SwiftUI
import UIKit // Necesario para la lógica de adaptabilidad (UIDevice.current)

struct GameView: View {
    // Usamos @ObservedObject porque el ViewModel se inicializa en ContentView y se pasa.
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var rankingManager: RankingManager
    
    @State private var showingGameOver = false
    
    // Propiedad calculada: Determina el número de columnas para la cuadrícula
    private var columns: [GridItem] {
        let totalCards = viewModel.cards.count
        
        guard totalCards > 0 else { return [] }
        
        let numColumns: Int
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad: Mayor densidad. Hasta 8 columnas.
            // Ejemplo: 40 cartas (8x5), 32 cartas (8x4), 20 cartas (5x4)
            // Se calcula el número de columnas basado en mantener las filas bajas.
            numColumns = min(8, Int(ceil(Double(totalCards) / 5.0)))
        } else {
            // iPhone/iPod: Mantenemos 4 columnas para 20 cartas (4x5)
            numColumns = 4
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
                    Text("Tiempo: **\(Score(playerName: "", timeInSeconds: viewModel.timeElapsed, mode: .color).displayTime)**")
                    Text("Volteos: **\(viewModel.flipCount)**")
                }
            }
            .font(.headline)
            .padding([.horizontal, .top])
            
            // Cuadrícula de Cartas con Columnas Dinámicas
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.cards) { card in
                    CardView(viewModel: viewModel, card: card)
                        // AspectRatio para mantener la forma vertical de la carta
                        .aspectRatio(2/3, contentMode: .fit)
                        .opacity(card.isMatched ? 0 : 1) // Oculta las cartas emparejadas
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
                showingGameOver = true
            }
        }
        
        // Pantalla de fin de juego (modal)
        .sheet(isPresented: $showingGameOver) {
            GameOverView(
                mode: viewModel.currentMode,
                score: viewModel.timeElapsed,
                rankingManager: rankingManager,
                onRestart: {
                    // Lógica para reiniciar el juego y cerrar el modal
                    viewModel.startGame()
                    showingGameOver = false
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
