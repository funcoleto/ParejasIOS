// ContentView.swift
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// --- Componentes del Juego de Puzzle ---

/// Una vista para configurar el juego de puzzle.
/// Permite al usuario seleccionar una imagen de su galería y elegir el tamaño de la cuadrícula.
struct PuzzleSetupView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var gridSize = 3 // Default: 3x3

    // Acceso a los ajustes para pasar al ViewModel
    @StateObject var settings = SettingsManager()

    var body: some View {
        VStack(spacing: 30) {
            Text("Modo Puzzle")
                .font(.largeTitle).bold()

            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(10)
                        .overlay(Text("Selecciona una imagen").foregroundColor(.gray))
                }

                Button("Elegir foto de la galería") {
                    showingImagePicker = true
                }
                .padding()
            }

            Stepper("Tamaño de la cuadrícula: \(gridSize)x\(gridSize)", value: $gridSize, in: 3...10)
                .padding(.horizontal)

            NavigationLink(destination: PuzzleGameView(viewModel: PuzzleViewModel(image: selectedImage!, gridSize: gridSize, settings: settings))) {
                Text("¡Empezar a Jugar!")
                    .font(.title2).bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedImage == nil ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedImage == nil)

            Spacer()
        }
        .padding()
        .navigationTitle("Configurar Puzzle")
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

// Vista de fin de juego para el modo puzzle
struct PuzzleGameOverView: View {
    @EnvironmentObject var rankingManager: RankingManager
    let score: TimeInterval
    let gridSize: Int
    let onPlayAgain: () -> Void
    let onMainMenu: () -> Void

    @State private var playerName: String = ""
    @State private var scoreSaved: Bool = false

    private var gridSizeString: String {
        "\(gridSize)x\(gridSize)"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("¡Puzzle Resuelto! 🥳")
                .font(.largeTitle).bold()

            Text("Tu Tiempo: **\(Score(playerName: "", timeInSeconds: score, mode: .puzzle, totalItems: 0).displayTime)**")
                .font(.title2)

            Text("Tamaño: **\(gridSizeString)**")
                .font(.headline)

            if !scoreSaved {
                TextField("Ingresa tu Nombre", text: $playerName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)

                Button("Guardar Puntuación") {
                    guard !playerName.isEmpty else { return }
                    // Aquí necesitamos una forma de guardar el tamaño de la cuadrícula en el objeto Score.
                    // Por ahora, lo dejaremos como 0. Lo arreglaremos en el siguiente paso.
                    let newScore = Score(
                        playerName: playerName,
                        timeInSeconds: score,
                        mode: .puzzle,
                        totalItems: gridSize * gridSize,
                        mathScore: nil,
                        puzzleGridSize: gridSizeString
                    )
                    rankingManager.saveScore(newScore: newScore)
                    scoreSaved = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("¡Puntuación guardada con éxito!")
                    .foregroundColor(.green)
            }

            Button("Jugar de Nuevo") {
                onPlayAgain()
            }
            .buttonStyle(.bordered)

            Button("Volver al Menú") {
                onMainMenu()
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
    }
}

// --- Componentes del Juego de Puzzle ---

// Enum para definir el tipo de borde de una pieza
enum TipoBorde: Int, Codable {
    case plano = 0
    case saliente = 1
    case entrante = -1

    // Retorna el tipo de borde complementario
    var opuesto: TipoBorde {
        switch self {
        case .plano: return .plano
        case .saliente: return .entrante
        case .entrante: return .saliente
        }
    }
}

// Estructura que define los cuatro bordes de una pieza
struct BordesPieza: Codable {
    var top: TipoBorde
    var bottom: TipoBorde
    var left: TipoBorde
    var right: TipoBorde

    static let standard = BordesPieza(top: .plano, bottom: .plano, left: .plano, right: .plano)
}

// Shape personalizado para dibujar la pieza de puzzle
struct FormaPuzzle: Shape {
    let bordes: BordesPieza

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Definimos el tamaño relativo de la "oreja" o pestaña del puzzle
        // Asumimos que el rect incluye el espacio para las pestañas salientes si es necesario,
        // pero para simplificar el layout en SwiftUI, a menudo dibujamos dentro del rect
        // y usamos un padding negativo o un frame mayor.
        // Aquí asumiremos que el 'rect' es el cuadrado base y las pestañas se dibujan
        // ligeramente fuera o dentro dependiendo de la implementación.
        // Para que encajen visualmente perfecto, lo ideal es insetar el rect base.

        // Ajuste: Vamos a considerar que 'rect' es el área total disponible.
        // El "cuerpo" de la pieza será un poco más pequeño para dar espacio a las pestañas salientes.
        // Alineamos con el ratio de recorte de la imagen (0.3 de extension / 1.6 total = 0.1875)
        let tabHeight = rect.width * (0.3 / 1.6)
        let baseRect = rect.insetBy(dx: tabHeight, dy: tabHeight)

        let minX = baseRect.minX
        let minY = baseRect.minY
        let maxX = baseRect.maxX
        let maxY = baseRect.maxY

        // Punto de inicio: Esquina superior izquierda
        path.move(to: CGPoint(x: minX, y: minY))

        // --- Borde Superior ---
        if bordes.top == .plano {
            path.addLine(to: CGPoint(x: maxX, y: minY))
        } else {
            addTab(to: &path, start: CGPoint(x: minX, y: minY), end: CGPoint(x: maxX, y: minY), type: bordes.top, isHorizontal: true)
        }

        // --- Borde Derecho ---
        if bordes.right == .plano {
            path.addLine(to: CGPoint(x: maxX, y: maxY))
        } else {
            addTab(to: &path, start: CGPoint(x: maxX, y: minY), end: CGPoint(x: maxX, y: maxY), type: bordes.right, isHorizontal: false)
        }

        // --- Borde Inferior ---
        if bordes.bottom == .plano {
            path.addLine(to: CGPoint(x: minX, y: maxY))
        } else {
            // Dibujamos de derecha a izquierda
            addTab(to: &path, start: CGPoint(x: maxX, y: maxY), end: CGPoint(x: minX, y: maxY), type: bordes.bottom, isHorizontal: true)
        }

        // --- Borde Izquierdo ---
        if bordes.left == .plano {
            path.addLine(to: CGPoint(x: minX, y: minY))
        } else {
            // Dibujamos de abajo a arriba
            addTab(to: &path, start: CGPoint(x: minX, y: maxY), end: CGPoint(x: minX, y: minY), type: bordes.left, isHorizontal: false)
        }

        path.closeSubpath()
        return path
    }

    // Función auxiliar para dibujar la pestaña
    private func addTab(to path: inout Path, start: CGPoint, end: CGPoint, type: TipoBorde, isHorizontal: Bool) {
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2
        let distance = isHorizontal ? abs(end.x - start.x) : abs(end.y - start.y)
        let tabSize = distance * 0.25 // Tamaño de la curva base
        let tabHeight = distance * 0.25 // Altura de la pestaña

        // Factor de dirección: 1 si es saliente, -1 si es entrante (pero depende de la dirección del trazado)
        // Si estamos dibujando el top (izq -> der), saliente es hacia arriba (-Y).
        // Si right (arriba -> abajo), saliente es derecha (+X).
        // Si bottom (der -> izq), saliente es abajo (+Y).
        // Si left (abajo -> arriba), saliente es izquierda (-X).

        // Determinamos el vector perpendicular "hacia afuera" del centro de la pieza
        var sign: CGFloat = type == .saliente ? 1.0 : -1.0

        // Ajuste de signo basado en la "normal" del lado
        // Top: normal es -Y. Right: +X. Bottom: +Y. Left: -X.
        // Pero nuestras coordenadas de dibujo siguen el perímetro.
        // Top (->): Curva a la izquierda del vector de dirección es "arriba".

        // Simplificación: Usaremos geometría relativa.

        // Puntos clave para una curva tipo puzzle estándar (Bézier)
        // Base del cuello: 1/3 y 2/3 del segmento? No, más complejo.
        // Usemos una forma estilizada.

        let seg1 = 0.35 * distance
        let seg2 = 0.65 * distance

        // Puntos sobre la línea base
        var p1, p2: CGPoint

        // Puntos de control y punta
        var c1, c2, tip: CGPoint

        // Offset perpendicular para la altura de la pestaña
        // Para saber hacia dónde es "afuera" o "adentro"
        // En un recorrido horario (Top->Right->Bottom->Left), "Afuera" es a la izquierda del trazo si el sistema de coord es estándar de pantalla Y-down?
        // Top: izq->der. Afuera es Arriba (-Y).
        // Right: arr->aba. Afuera es Derecha (+X).
        // Bottom: der->izq. Afuera es Abajo (+Y).
        // Left: aba->arr. Afuera es Izquierda (-X).

        // Sin embargo, 'type' define saliente/entrante respecto al centro de la pieza.
        // Top saliente = -Y. Top entrante = +Y.

        // Vamos a calcular el offset vector.
        let dx = end.x - start.x
        let dy = end.y - start.y

        // Normalizada
        let length = sqrt(dx*dx + dy*dy)
        let nx = dx / length
        let ny = dy / length

        // Vector perpendicular (girado -90 grados para apuntar "afuera" en recorrido horario)
        // (x, y) -> (y, -x)
        var perpX = ny
        var perpY = -nx

        // Si es entrante, invertimos el vector perpendicular
        if type == .entrante {
            perpX = -perpX
            perpY = -perpY
        }

        // Puntos base en la línea
        p1 = CGPoint(x: start.x + dx * 0.35, y: start.y + dy * 0.35)
        p2 = CGPoint(x: start.x + dx * 0.65, y: start.y + dy * 0.65)

        // La punta de la pestaña
        let tipX = start.x + dx * 0.5 + perpX * tabHeight
        let tipY = start.y + dy * 0.5 + perpY * tabHeight
        tip = CGPoint(x: tipX, y: tipY)

        // Puntos de control. Para hacerlo "bombilla" necesitamos que el cuello se estreche un poco o sea recto.
        // Haremos una curva suave cúbica.

        // C1: Control para subir desde p1. Un poco hacia la punta.
        let c1X = p1.x + perpX * (tabHeight * 1.2)
        let c1Y = p1.y + perpY * (tabHeight * 1.2)

        // C2: Control para bajar hacia p2.
        let c2X = p2.x + perpX * (tabHeight * 1.2)
        let c2Y = p2.y + perpY * (tabHeight * 1.2)

        // Dibujamos la línea hasta el inicio de la pestaña
        path.addLine(to: p1)

        // Dibujamos la pestaña con 3 curvas o 1 curva compleja?
        // Una curva simple cubic bezier p1 -> tip -> p2 suele quedar muy triangular.
        // Usaremos un estilo más "pieza de puzzle" con un cuello.

        let shoulder = tabSize * 0.2

        let neck1 = CGPoint(x: p1.x + perpX * shoulder, y: p1.y + perpY * shoulder)
        let neck2 = CGPoint(x: p2.x + perpX * shoulder, y: p2.y + perpY * shoulder)

        // Vamos a hacer algo más simple pero efectivo: Curva hacia la punta y vuelta.
        // Usamos quad curves para un look más orgánico.

        path.addCurve(to: tip,
                      control1: CGPoint(x: p1.x + perpX * tabHeight * 0.2, y: p1.y + perpY * tabHeight * 0.2), // Cuello 1
                      control2: CGPoint(x: tip.x - dx * 0.2, y: tip.y - dy * 0.2)) // Lado 1

        path.addCurve(to: p2,
                      control1: CGPoint(x: tip.x + dx * 0.2, y: tip.y + dy * 0.2), // Lado 2
                      control2: CGPoint(x: p2.x + perpX * tabHeight * 0.2, y: p2.y + perpY * tabHeight * 0.2)) // Cuello 2

        // Línea hasta el final
        path.addLine(to: end)
    }
}

/// Representa una única pieza del puzzle.
struct PuzzlePiece: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let originalIndex: Int
    let bordes: BordesPieza

    // Equatable conformance
    static func == (lhs: PuzzlePiece, rhs: PuzzlePiece) -> Bool {
        lhs.id == rhs.id
    }
}

/// Gestiona la lógica del juego de puzzle.
import Combine

class PuzzleViewModel: ObservableObject {
    @Published var pieces: [PuzzlePiece] = []
    @Published var board: [PuzzlePiece?]
    @Published var isSolved: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var showHints: Bool

    private(set) var originalPieces: [PuzzlePiece] = []

    let gridSize: Int
    private var timer: AnyCancellable?
    private let startTime = Date()
    let settings: SettingsManager

    init(image: UIImage, gridSize: Int, settings: SettingsManager) {
        self.gridSize = gridSize
        self.settings = settings
        self.showHints = settings.showPuzzleHints
        self.board = Array(repeating: nil, count: gridSize * gridSize)
        self.pieces = self.sliceImage(image: image, gridSize: gridSize)
        startTimer()
    }

    private func sliceImage(image: UIImage, gridSize: Int) -> [PuzzlePiece] {
        guard let cgImage = image.cgImage else { return [] }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let pieceWidth = width / CGFloat(gridSize)
        let pieceHeight = height / CGFloat(gridSize)

        // 1. Generar la matriz de bordes
        var edgesMatrix = Array(repeating: Array(repeating: BordesPieza.standard, count: gridSize), count: gridSize)

        for y in 0..<gridSize {
            for x in 0..<gridSize {
                var bordes = BordesPieza.standard

                // Top
                if y == 0 {
                    bordes.top = .plano
                } else {
                    bordes.top = edgesMatrix[y-1][x].bottom.opuesto
                }

                // Bottom
                if y == gridSize - 1 {
                    bordes.bottom = .plano
                } else {
                    bordes.bottom = Bool.random() ? .saliente : .entrante
                }

                // Left
                if x == 0 {
                    bordes.left = .plano
                } else {
                    bordes.left = edgesMatrix[y][x-1].right.opuesto
                }

                // Right
                if x == gridSize - 1 {
                    bordes.right = .plano
                } else {
                    bordes.right = Bool.random() ? .saliente : .entrante
                }

                edgesMatrix[y][x] = bordes
            }
        }

        var slicedPieces: [PuzzlePiece] = []
        let tabRatio: CGFloat = 0.3 // Margen extra para las pestañas

        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let bordes = edgesMatrix[y][x]

                // Calcular el rectángulo base
                let baseX = CGFloat(x) * pieceWidth
                let baseY = CGFloat(y) * pieceHeight

                // Expandir el rectángulo para incluir las pestañas
                // Necesitamos capturar suficiente imagen alrededor para que cuando la máscara dibuje la pestaña, haya imagen debajo.
                // Expandimos hacia todas las direcciones un 30% del tamaño de la pieza
                let extensionX = pieceWidth * tabRatio
                let extensionY = pieceHeight * tabRatio

                let cropRect = CGRect(
                    x: baseX - extensionX,
                    y: baseY - extensionY,
                    width: pieceWidth + (extensionX * 2),
                    height: pieceHeight + (extensionY * 2)
                )

                // Aseguramos que cropRect interseccione con la imagen. Si se sale (coordenadas negativas), usamos lo que hay.
                // Como necesitamos que la imagen final tenga el tamaño exacto (incluyendo extensiones) para que la máscara encaje,
                // creamos un contexto del tamaño deseado y dibujamos la parte disponible de la imagen en la posición correcta.

                // 1. Calcular la intersección segura con la imagen original
                let imageBounds = CGRect(x: 0, y: 0, width: width, height: height)
                let safeCropRect = cropRect.intersection(imageBounds)

                if let slicedCGImage = cgImage.cropping(to: safeCropRect) {
                    let uiImage: UIImage

                    // Si el recorte seguro es igual al deseado (caso interno), usamos la imagen directamente
                    if safeCropRect == cropRect {
                         uiImage = UIImage(cgImage: slicedCGImage, scale: image.scale, orientation: image.imageOrientation)
                    } else {
                        // Si falta un trozo (bordes), pintamos en un contexto del tamaño completo
                        // El tamaño objetivo es cropRect.size
                        let targetSize = cropRect.size
                        let format = UIGraphicsImageRendererFormat()
                        format.scale = image.scale
                        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

                        uiImage = renderer.image { context in
                            // Calcular dónde dibujar el trozo recortado
                            // La diferencia entre el inicio seguro y el inicio deseado nos da el offset
                            let drawX = safeCropRect.minX - cropRect.minX
                            let drawY = safeCropRect.minY - cropRect.minY

                            let partialImage = UIImage(cgImage: slicedCGImage, scale: image.scale, orientation: image.imageOrientation)
                            partialImage.draw(at: CGPoint(x: drawX, y: drawY))
                        }
                    }

                    let index = y * gridSize + x
                    let piece = PuzzlePiece(image: uiImage, originalIndex: index, bordes: bordes)
                    slicedPieces.append(piece)
                }
            }
        }

        // Guardamos las piezas en su orden original para las pistas
        self.originalPieces = slicedPieces.sorted(by: { $0.originalIndex < $1.originalIndex })

        return slicedPieces.shuffled()
    }

    func placePiece(_ piece: PuzzlePiece, at index: Int) {
        // Si la celda ya tiene una pieza, la devolvemos a la mano antes de poner la nueva (o intercambiamos)
        if let existingPiece = board[index] {
            pieces.append(existingPiece)
        }

        board[index] = piece
        pieces.removeAll { $0.id == piece.id }
        checkIfSolved()
    }

    func returnPiece(fromBoardIndex index: Int) {
        guard let pieceToReturn = board[index] else { return }
        board[index] = nil
        pieces.append(pieceToReturn)
        if isSolved {
            isSolved = false
        }
    }

    // Función para devolver una pieza específica (usada al arrastrar desde el tablero)
    func removePiece(_ piece: PuzzlePiece) {
        if let index = board.firstIndex(of: piece) {
            board[index] = nil
            pieces.append(piece)
            if isSolved { isSolved = false }
        }
    }

    func reorderPieceInHand(piece: PuzzlePiece, droppedOn targetPiece: PuzzlePiece) {
        guard let fromIndex = pieces.firstIndex(of: piece),
              let toIndex = pieces.firstIndex(of: targetPiece) else { return }

        pieces.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
    }

    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsedTime = Date().timeIntervalSince(self.startTime)
            }
    }

    func stopTimer() {
        timer?.cancel()
    }

    deinit {
        stopTimer()
    }

    private func checkIfSolved() {
        let isBoardFull = board.allSatisfy { $0 != nil }
        if isBoardFull {
            for (index, piece) in board.enumerated() {
                if piece?.originalIndex != index {
                    isSolved = false
                    return
                }
            }
            isSolved = true
            stopTimer()
        }
    }
}

/// La vista principal del juego de puzzle, que muestra el tablero y las piezas arrastrables.
struct PuzzleGameView: View {
    @StateObject var viewModel: PuzzleViewModel
    @State private var showingGameOver = false
    @Environment(\.presentationMode) var presentationMode

    // Estado para controlar el drag
    @State private var draggingPiece: PuzzlePiece?

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: viewModel.gridSize)

        VStack {
            // --- Cabecera ---
            HStack {
                Text("Tiempo: \(Score(playerName: "", timeInSeconds: viewModel.elapsedTime, mode: .puzzle, totalItems: 0, puzzleGridSize: nil).displayTime)")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
            }
            .padding(.top)

            // --- Tablero de Puzzle ---
            GeometryReader { geo in
                // Calculamos el tamaño de la celda para asegurar el ajuste
                let totalWidth = geo.size.width - 40 // Margen
                let cellSize = totalWidth / CGFloat(viewModel.gridSize)

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(0..<viewModel.board.count, id: \.self) { index in
                        ZStack {
                            // Fondo de celda vacía
                            // Eliminamos el fondo gris transparente (ahora es clear)
                            // Si está activada la ayuda (showHints), mostramos la silueta
                            if viewModel.board[index] == nil {
                                Rectangle()
                                    .fill(Color.clear)
                                    .border(Color.white.opacity(0.1), width: 0.5) // Borde muy sutil para guía visual

                                if viewModel.showHints && index < viewModel.originalPieces.count {
                                    // Usamos la pieza original para saber la forma correcta
                                    let originalPiece = viewModel.originalPieces[index]

                                    // Dibujamos solo el contorno o una forma semitransparente muy suave
                                    // Necesitamos escalar igual que en PieceView
                                    let scaleFactor: CGFloat = 1.6

                                    FormaPuzzle(bordes: originalPiece.bordes)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                        .frame(width: cellSize * scaleFactor, height: cellSize * scaleFactor)
                                        .allowsHitTesting(false)
                                }
                            }

                            // Pieza colocada
                            if let piece = viewModel.board[index] {
                                PieceView(piece: piece, cellSize: cellSize)
                                    .onDrag {
                                        self.draggingPiece = piece
                                        return NSItemProvider(object: piece.id.uuidString as NSString)
                                    }
                            }
                        }
                        .frame(height: cellSize) // Forzamos altura cuadrada
                        .zIndex(viewModel.board[index] != nil ? 1 : 0) // Piezas por encima
                        .contentShape(Rectangle()) // Asegura que toda la celda recibe el drop
                        .onDrop(of: [UTType.text.identifier, UTType.plainText.identifier], isTargeted: nil) { providers, _ in
                            handleDropOnBoard(providers: providers, index: index)
                        }
                    }
                }
                .padding(20)
                .frame(width: geo.size.width, alignment: .center)
            }
            .frame(maxHeight: .infinity) // El tablero ocupa el espacio central

            // --- Barra Inferior (Mano) ---
            // Área para soltar piezas y quitarlas del tablero
            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 120)
                    .overlay(
                        Text("Arrastra aquí para quitar")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 5),
                        alignment: .top
                    )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(viewModel.pieces) { piece in
                            PieceView(piece: piece, cellSize: 80) // Tamaño fijo en la barra
                                .frame(width: 80, height: 80)
                                .onDrag {
                                    self.draggingPiece = piece
                                    return NSItemProvider(object: piece.id.uuidString as NSString)
                                }
                                .onDrop(of: [UTType.text.identifier, UTType.plainText.identifier], isTargeted: nil) { providers, _ in
                                    handleDropOnHand(providers: providers, targetPiece: piece)
                                }
                        }
                    }
                    .padding()
                    .frame(minWidth: UIScreen.main.bounds.width) // Asegurar que ocupe todo el ancho para recibir drops vacíos
                }
            }
            .contentShape(Rectangle())
            .onDrop(of: [UTType.text.identifier, UTType.plainText.identifier], isTargeted: nil) { providers, _ in
                // Drop genérico en la barra (para quitar del tablero sin reordenar específico)
                handleDropOnBar(providers: providers)
            }
        }
        .navigationTitle("Puzzle")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isSolved) { isSolved in
            if isSolved {
                showingGameOver = true
            }
        }
        .sheet(isPresented: $showingGameOver) {
            PuzzleGameOverView(
                score: viewModel.elapsedTime,
                gridSize: viewModel.gridSize,
                onPlayAgain: {
                    showingGameOver = false
                    presentationMode.wrappedValue.dismiss()
                },
                onMainMenu: {
                    showingGameOver = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    // --- Lógica de Drop ---

    private func handleDropOnBoard(providers: [NSItemProvider], index: Int) -> Bool {
        guard let provider = providers.first else { return false }

        // Intentamos cargar como texto plano o UTF8, ya que NSItemProvider(object: String) puede usar diferentes identificadores
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, error) in
                if let data = data as? Data, let id = String(data: data, encoding: .utf8) {
                    processDropOnBoard(id: id, index: index)
                } else if let text = data as? String {
                     processDropOnBoard(id: text, index: index)
                }
            }
        } else {
            provider.loadObject(ofClass: NSString.self) { (idString, error) in
                if let id = idString as? String {
                    processDropOnBoard(id: id, index: index)
                }
            }
        }
        return true
    }

    private func processDropOnBoard(id: String, index: Int) {
        DispatchQueue.main.async {
                // Buscar en la mano
                if let piece = viewModel.pieces.first(where: { $0.id.uuidString == id }) {
                    viewModel.placePiece(piece, at: index)
                }
                // Buscar en el tablero (mover de una celda a otra)
                else if let existingIndex = viewModel.board.firstIndex(where: { $0?.id.uuidString == id }),
                        let piece = viewModel.board[existingIndex] {
                    viewModel.returnPiece(fromBoardIndex: existingIndex)
                    viewModel.placePiece(piece, at: index)
                }
            }
    }

    private func handleDropOnHand(providers: [NSItemProvider], targetPiece: PuzzlePiece) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSString.self) { (idString, error) in
            guard let id = idString as? String else { return }

            DispatchQueue.main.async {
                // Si viene de la mano (reordenar)
                if let sourcePiece = viewModel.pieces.first(where: { $0.id.uuidString == id }) {
                    viewModel.reorderPieceInHand(piece: sourcePiece, droppedOn: targetPiece)
                }
                // Si viene del tablero (quitar)
                else if let existingIndex = viewModel.board.firstIndex(where: { $0?.id.uuidString == id }),
                        let piece = viewModel.board[existingIndex] {
                    viewModel.removePiece(piece)
                    // Opcional: Moverla cerca de la targetPiece
                }
            }
        }
        return true
    }

    private func handleDropOnBar(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSString.self) { (idString, error) in
            guard let id = idString as? String else { return }

            DispatchQueue.main.async {
                // Solo nos interesa si viene del tablero para quitarla
                if let existingIndex = viewModel.board.firstIndex(where: { $0?.id.uuidString == id }),
                   let piece = viewModel.board[existingIndex] {
                    viewModel.removePiece(piece)
                }
            }
        }
        return true
    }
}

/// Vista auxiliar para renderizar una pieza con su forma y máscara
struct PieceView: View {
    let piece: PuzzlePiece
    let cellSize: CGFloat

    var body: some View {
        // La imagen recortada incluye un margen extra del 30% (tabRatio).
        // Total width = base + 2 * 0.3 * base = 1.6 * base.
        // El frame debe ser 1.6 veces el cellSize.
        let scaleFactor: CGFloat = 1.6

        Image(uiImage: piece.image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: cellSize * scaleFactor, height: cellSize * scaleFactor)
            // Aplicamos la máscara de forma de puzzle
            .mask(
                FormaPuzzle(bordes: piece.bordes)
                    .frame(width: cellSize * scaleFactor, height: cellSize * scaleFactor)
            )
            // Desactivamos el clipping para que las pestañas sobresalgan de su celda lógica
            // .allowsHitTesting(false) // Eliminado para permitir que el drag funcione correctamente
            .contentShape(FormaPuzzle(bordes: piece.bordes)) // Usamos la forma exacta para el hit testing
    }
}

/// Helper para el selector de imágenes de UIKit
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}



// ContentView.swift

/// La vista principal de la aplicación que actúa como menú principal.
/// Desde aquí, el usuario puede navegar a los diferentes modos de juego, ver el ranking y acceder a las opciones.
struct ContentView: View {
    /// Gestiona el ranking de puntuaciones.
    @StateObject var rankingManager = RankingManager()
    @StateObject var settingsManager = SettingsManager()
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingOperationSelection = false
    @State private var selectedGameMode: GameMode?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                Text("Juego de Parejas 🧠")
                    .font(.largeTitle).bold()
                    .padding(.bottom, 40)
                
                // Botones de modo de juego
                ForEach(GameMode.allCases, id: \.self) { mode in
                    GameModeButton(mode: mode,
                                   settingsManager: settingsManager,
                                   rankingManager: rankingManager,
                                   showingOperationSelection: $showingOperationSelection,
                                   selectedGameMode: $selectedGameMode)
                }
                
                Spacer()
                
                // Botones de Ranking y Opciones
                HStack(spacing: 20) {
                    NavigationLink(destination: RankingView(rankingManager: rankingManager)) {
                        Text("🏆 Ranking")
                            .font(.title3).bold()
                            .padding()
                            .foregroundColor(.blue)
                    }

                    NavigationLink(destination: OptionsView(settings: settingsManager)) {
                        Text("⚙️ Opciones")
                            .font(.title3).bold()
                            .padding()
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Menú Principal")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if settingsManager.isMusicEnabled {
                audioManager.play()
            }
        }
        .onChange(of: settingsManager.isMusicEnabled) { isEnabled in
            if isEnabled {
                audioManager.play()
            } else {
                audioManager.pause()
            }
        }
        .sheet(isPresented: $showingOperationSelection) {
            OperationSelectionView(settings: settingsManager, rankingManager: rankingManager)
        }
        .environmentObject(rankingManager)
    }
}

/// Un botón personalizado para el menú principal que navega al modo de juego correspondiente.
struct GameModeButton: View {
    let mode: GameMode
    let settingsManager: SettingsManager
    let rankingManager: RankingManager
    @Binding var showingOperationSelection: Bool
    @Binding var selectedGameMode: GameMode?

    var body: some View {
        switch mode {
        case .matematicas:
            Button(action: {
                selectedGameMode = mode
                showingOperationSelection = true
            }) {
                buttonContent(text: "Modo \(mode.rawValue)", color: .green)
            }
        case .puzzle:
            NavigationLink(destination: PuzzleSetupView()) {
                buttonContent(text: "Modo \(mode.rawValue)", color: .orange)
            }
        default:
            NavigationLink(destination: GameView(viewModel: GameViewModel(mode: mode, settings: settingsManager), rankingManager: rankingManager)) {
                buttonContent(text: "Modo \(mode.rawValue)", color: .blue)
            }
        }
    }

    /// Crea el contenido visual del botón.
    private func buttonContent(text: String, color: Color) -> some View {
        Text(text)
            .font(.title2)
            .frame(maxWidth: 300)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

// Vista para mostrar la operación matemática
struct OperationDisplayView: View {
    let problem: MathProblem

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text(String(problem.operand1))
                Spacer()
                Text(bars(for: problem.operand1))
            }
            HStack {
                Text(operationSymbol(for: problem.operation))
                Text(String(problem.operand2))
                Spacer()
                Text(bars(for: problem.operand2))
            }
            Rectangle()
                .frame(height: 2)
                .padding(.leading, 20)
        }
        .font(.largeTitle)
        .frame(width: 200)
    }

    private func operationSymbol(for type: OperationType) -> String {
        switch type {
        case .suma: return "+"
        case .resta: return "-"
        case .multiplicacion: return "x"
        case .division: return "÷"
        }
    }

    private func bars(for number: Int) -> String {
        guard number < 10 else { return "" }
        return String(repeating: "|", count: number)
    }
}

import Foundation

class SettingsManager: ObservableObject {
    @Published var numberOfPairs: Int {
        didSet {
            UserDefaults.standard.set(numberOfPairs, forKey: "numberOfPairs")
        }
    }

    @Published var showMatchedCards: Bool {
        didSet {
            UserDefaults.standard.set(showMatchedCards, forKey: "showMatchedCards")
        }
    }

    @Published var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "isMusicEnabled")
        }
    }

    @Published var numberOfOperations: Int {
        didSet {
            UserDefaults.standard.set(numberOfOperations, forKey: "numberOfOperations")
        }
    }

    @Published var showPuzzleHints: Bool {
        didSet {
            UserDefaults.standard.set(showPuzzleHints, forKey: "showPuzzleHints")
        }
    }

    init() {
        self.numberOfPairs = UserDefaults.standard.object(forKey: "numberOfPairs") as? Int ?? 10
        self.showMatchedCards = UserDefaults.standard.object(forKey: "showMatchedCards") as? Bool ?? false
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true
        self.numberOfOperations = UserDefaults.standard.object(forKey: "numberOfOperations") as? Int ?? 4
        self.showPuzzleHints = UserDefaults.standard.object(forKey: "showPuzzleHints") as? Bool ?? true
    }
}

struct OptionsView: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        Form {
            Section(header: Text("Configuración del Juego")) {
                Stepper(value: $settings.numberOfPairs, in: 2...24) {
                    Text("Número de Parejas: \(settings.numberOfPairs)")
                }

                Toggle(isOn: $settings.showMatchedCards) {
                    Text("Mostrar Cartas Emparejadas")
                }

                Toggle(isOn: $settings.isMusicEnabled) {
                    Text("Música de Fondo")
                }
            }

            Section(header: Text("Configuración del Puzzle")) {
                Toggle(isOn: $settings.showPuzzleHints) {
                    Text("Mostrar silueta de piezas")
                }
            }

            Section(header: Text("Juego de Matemáticas")) {
                Stepper(value: $settings.numberOfOperations, in: 2...20) {
                    Text("Número de Operaciones: \(settings.numberOfOperations)")
                }
            }
        }
        .navigationTitle("Opciones")
    }
}

// --- Componentes del Juego de Matemáticas ---

// Enum para los tipos de operación
enum OperationType: String, CaseIterable, Identifiable {
    case suma = "Suma"
    case resta = "Resta"
    case multiplicacion = "Multiplicación"
    case division = "División"
    var id: Self { self }
}

// Estructura para un problema matemático
struct MathProblem {
    let operand1: Int
    let operand2: Int
    let operation: OperationType
    let answer: Int
}

// Vista para seleccionar las operaciones
struct OperationSelectionView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var rankingManager: RankingManager
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedOperations = Set<OperationType>()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Elige las operaciones")) {
                    ForEach(OperationType.allCases) { operation in
                        Toggle(operation.rawValue, isOn: Binding(
                            get: { selectedOperations.contains(operation) },
                            set: { isOn in
                                if isOn {
                                    selectedOperations.insert(operation)
                                } else {
                                    selectedOperations.remove(operation)
                                }
                            }
                        ))
                    }
                }

                Section {
                    NavigationLink(destination: MathGameView(viewModel: MathViewModel(settings: settings, operations: selectedOperations, audioManager: audioManager), rankingManager: rankingManager)) {
                        Text("¡A Jugar!")
                    }
                    .disabled(selectedOperations.isEmpty)
                }
            }
            .navigationTitle("Modo Matemáticas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// ViewModel para el juego de matemáticas
class MathViewModel: ObservableObject {
    @Published var currentProblem: MathProblem? = nil
    @Published var userAnswer: String = ""
    @Published var score: Int = 0
    @Published var remainingOperations: Int
    @Published var isGameOver: Bool = false
    @Published var isShowingAnswer: Bool = false

    let settings: SettingsManager
    private let operations: [OperationType]
    private let audioManager: AudioManager

    init(settings: SettingsManager, operations: Set<OperationType>, audioManager: AudioManager) {
        self.settings = settings
        self.operations = Array(operations)
        self.remainingOperations = settings.numberOfOperations
        self.audioManager = audioManager
        generateNewOperation()
    }

    func generateNewOperation() {
        guard let operationType = operations.randomElement() else { return }
        var operand1: Int
        var operand2: Int
        var answer: Int

        switch operationType {
        case .suma:
            operand1 = Int.random(in: 1...20)
            operand2 = Int.random(in: 1...20)
            answer = operand1 + operand2
        case .resta:
            operand1 = Int.random(in: 10...30)
            operand2 = Int.random(in: 1...operand1)
            answer = operand1 - operand2
        case .multiplicacion:
            operand1 = Int.random(in: 2...10)
            operand2 = Int.random(in: 2...10)
            answer = operand1 * operand2
        case .division:
            operand2 = Int.random(in: 2...10)
            answer = Int.random(in: 2...10)
            operand1 = operand2 * answer
        }
        currentProblem = MathProblem(operand1: operand1, operand2: operand2, operation: operationType, answer: answer)
    }

    func submitAnswer() {
        guard let correctAnswer = currentProblem?.answer else { return }

        if Int(userAnswer) == correctAnswer {
            score += 1
            audioManager.playSoundEffect(named: "acierto")
        } else {
            audioManager.playSoundEffect(named: "fallo")
        }
        isShowingAnswer = true
    }

    func nextOperation() {
        remainingOperations -= 1
        userAnswer = ""
        isShowingAnswer = false

        if remainingOperations > 0 {
            generateNewOperation()
        } else {
            isGameOver = true
        }
    }

    func resetGame() {
        score = 0
        remainingOperations = settings.numberOfOperations
        userAnswer = ""
        isShowingAnswer = false
        isGameOver = false
        generateNewOperation()
    }
}

// Vista para el juego de matemáticas
struct MathGameView: View {
    @ObservedObject var viewModel: MathViewModel
    @ObservedObject var rankingManager: RankingManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingGameOver = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Operaciones Restantes: \(viewModel.remainingOperations)")
                .font(.headline)

            if let problem = viewModel.currentProblem {
                if viewModel.isShowingAnswer {
                    VStack {
                        OperationDisplayView(problem: problem)
                        Text(String(problem.answer))
                            .font(.largeTitle)
                            .foregroundColor(Int(viewModel.userAnswer) == problem.answer ? .green : .red)
                    }
                } else {
                    OperationDisplayView(problem: problem)
                }
            }

            if viewModel.isShowingAnswer {
                Button("Continuar") {
                    viewModel.nextOperation()
                }
                .padding()
            } else {
                TextField("Respuesta", text: $viewModel.userAnswer)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)

                Button("Enviar") {
                    viewModel.submitAnswer()
                }
                .disabled(viewModel.userAnswer.isEmpty)
            }
        }
        .navigationTitle("Matemáticas")
        .onChange(of: viewModel.isGameOver) { isGameOver in
            if isGameOver {
                showingGameOver = true
            }
        }
        .sheet(isPresented: $showingGameOver) {
            MathGameOverView(
                score: viewModel.score,
                totalOperations: viewModel.settings.numberOfOperations,
                rankingManager: rankingManager,
                onPlayAgain: {
                    showingGameOver = false
                    viewModel.resetGame()
                },
                onMainMenu: {
                    showingGameOver = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// Vista de fin de juego para el modo matemáticas
struct MathGameOverView: View {
    let score: Int
    let totalOperations: Int
    @ObservedObject var rankingManager: RankingManager
    let onPlayAgain: () -> Void
    let onMainMenu: () -> Void

    @State private var playerName: String = ""
    @State private var scoreSaved: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("¡Juego Terminado! 🥳")
                .font(.largeTitle).bold()

            Text("Puntuación: **\(score) / \(totalOperations)**")
                .font(.title2)

            if !scoreSaved {
                TextField("Ingresa tu Nombre", text: $playerName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)

                Button("Guardar Puntuación") {
                    guard !playerName.isEmpty else { return }
                    let newScore = Score(
                        playerName: playerName,
                        timeInSeconds: 0,
                        mode: .matematicas,
                        totalItems: totalOperations,
                        mathScore: score,
                        puzzleGridSize: nil
                    )
                    rankingManager.saveScore(newScore: newScore)
                    scoreSaved = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("¡Puntuación guardada con éxito!")
                    .foregroundColor(.green)
            }

            Button("Jugar de Nuevo") {
                onPlayAgain()
            }
            .buttonStyle(.bordered)

            Button("Volver al Menú Principal") {
                onMainMenu()
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
    }
}
