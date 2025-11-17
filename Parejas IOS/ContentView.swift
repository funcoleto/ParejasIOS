// ContentView.swift
import SwiftUI
import PhotosUI

// --- Componentes del Juego de Puzzle ---

/// Una vista para configurar el juego de puzzle.
/// Permite al usuario seleccionar una imagen de su galería y elegir el tamaño de la cuadrícula.
struct PuzzleSetupView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var gridSize = 3 // Default: 3x3

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

            NavigationLink(destination: PuzzleGameView(viewModel: PuzzleViewModel(image: selectedImage!, gridSize: gridSize))) {
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

// --- Componentes para la Forma de la Pieza del Puzzle ---

// MARK: - Helpers de Geometría
extension CGPoint {
    // Suma dos puntos como si fueran vectores
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    // Interpola linealmente entre dos puntos
    func lerp(to point: CGPoint, t: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + (point.x - self.x) * t, y: self.y + (point.y - self.y) * t)
    }
}


/// Define el tipo de borde de una pieza del puzzle.
enum EdgeType {
    case flat, inwards, outwards
}

/// Una `Shape` que dibuja el contorno de una pieza de puzzle basándose en sus cuatro bordes.
struct PuzzlePieceShape: Shape {
    var top: EdgeType
    var right: EdgeType
    var bottom: EdgeType
    var left: EdgeType

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tabSize = min(rect.width, rect.height) / 3.5 // Controla el tamaño del saliente

        // Puntos de las esquinas del rectángulo
        let p_tl = CGPoint(x: rect.minX, y: rect.minY)
        let p_tr = CGPoint(x: rect.maxX, y: rect.minY)
        let p_br = CGPoint(x: rect.maxX, y: rect.maxY)
        let p_bl = CGPoint(x: rect.minX, y: rect.maxY)

        // Empezar en la esquina superior izquierda
        path.move(to: p_tl)

        // Dibujar cada borde en sentido horario
        drawEdge(path: &path, edgeType: top, from: p_tl, to: p_tr, tabSize: tabSize)
        drawEdge(path: &path, edgeType: right, from: p_tr, to: p_br, tabSize: tabSize)
        drawEdge(path: &path, edgeType: bottom, from: p_br, to: p_bl, tabSize: tabSize)
        drawEdge(path: &path, edgeType: left, from: p_bl, to: p_tl, tabSize: tabSize)

        return path
    }

    /// Dibuja un único borde (lado) de la pieza del puzzle.
    /// - Parameters:
    ///   - path: El `Path` de SwiftUI al que se añadirá el borde.
    ///   - edgeType: El tipo de borde a dibujar (`flat`, `inwards`, `outwards`).
    ///   - p1: El punto de inicio del borde.
    ///   - p2: El punto final del borde.
    ///   - tabSize: El tamaño del saliente o entrante.
    private func drawEdge(path: inout Path, edgeType: EdgeType, from p1: CGPoint, to p2: CGPoint, tabSize: CGFloat) {
        switch edgeType {
        case .flat:
            path.addLine(to: p2)

        case .outwards, .inwards:
            let multiplier: CGFloat = edgeType == .outwards ? 1 : -1

            // Puntos a lo largo del borde
            let p3_8 = p1.lerp(to: p2, t: 0.375)
            let p4_8 = p1.lerp(to: p2, t: 0.5)
            let p5_8 = p1.lerp(to: p2, t: 0.625)

            // Vectores
            let tangent = CGPoint(x: (p2.x - p1.x), y: (p2.y - p1.y))
            let normal = CGPoint(x: tangent.y * multiplier, y: -tangent.x * multiplier)

            // Puntos de control
            let c1 = p3_8
            let c2 = p3_8 + CGPoint(x: normal.x * 0.25, y: normal.y * 0.25)
            let c3 = p4_8 + CGPoint(x: normal.x * 0.25, y: normal.y * 0.25)
            let c4 = p4_8
            let c5 = p4_8 + CGPoint(x: normal.x * 0.25, y: normal.y * 0.25)
            let c6 = p5_8 + CGPoint(x: normal.x * 0.25, y: normal.y * 0.25)
            let c7 = p5_8

            // Dibujar la forma
            path.addLine(to: c1)
            path.addCurve(to: c4, control1: c2, control2: c3)
            path.addCurve(to: c7, control1: c5, control2: c6)
            path.addLine(to: p2)
        }
    }
}


/// Representa una única pieza del puzzle.
struct PuzzlePiece: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let originalIndex: Int
    let shape: PuzzlePieceShape

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

    private(set) var originalPieces: [PuzzlePiece] = []

    let gridSize: Int
    private var timer: AnyCancellable?
    private let startTime = Date()

    init(image: UIImage, gridSize: Int) {
        self.gridSize = gridSize
        self.board = Array(repeating: nil, count: gridSize * gridSize)
        self.pieces = self.sliceImage(image: image, gridSize: gridSize)
        startTimer()
    }

    private func sliceImage(image: UIImage, gridSize: Int) -> [PuzzlePiece] {
        guard let cgImage = image.cgImage else { return [] }

        let pieceWidth = CGFloat(cgImage.width) / CGFloat(gridSize)
        let pieceHeight = CGFloat(cgImage.height) / CGFloat(gridSize)
        var slicedPieces: [PuzzlePiece] = []

        // Generar todas las formas de las piezas primero
        let shapes = generatePieceShapes()

        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let rect = CGRect(x: CGFloat(x) * pieceWidth, y: CGFloat(y) * pieceHeight, width: pieceWidth, height: pieceHeight)
                if let slicedCGImage = cgImage.cropping(to: rect) {
                    let uiImage = UIImage(cgImage: slicedCGImage, scale: image.scale, orientation: image.imageOrientation)
                    let index = y * gridSize + x
                    let piece = PuzzlePiece(image: uiImage, originalIndex: index, shape: shapes[index])
                    slicedPieces.append(piece)
                }
            }
        }

        self.originalPieces = slicedPieces
        return slicedPieces.shuffled()
    }

    /// Genera una cuadrícula de formas de piezas de puzzle que encajan entre sí.
    private func generatePieceShapes() -> [PuzzlePieceShape] {
        let gridSize = self.gridSize
        var shapes: [PuzzlePieceShape] = []

        // Matrices para los bordes horizontales y verticales internos
        var horizontalEdges = Array(repeating: Array(repeating: EdgeType.flat, count: gridSize), count: gridSize - 1)
        var verticalEdges = Array(repeating: Array(repeating: EdgeType.flat, count: gridSize - 1), count: gridSize)

        // Asignar aleatoriamente los bordes internos
        for row in 0..<(gridSize - 1) {
            for col in 0..<gridSize {
                horizontalEdges[row][col] = Bool.random() ? .inwards : .outwards
            }
        }
        for row in 0..<gridSize {
            for col in 0..<(gridSize - 1) {
                verticalEdges[row][col] = Bool.random() ? .inwards : .outwards
            }
        }

        // Crear la forma para cada pieza
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                // El borde superior es el borde inferior de la pieza de arriba, o plano si está en el borde.
                let top = row == 0 ? EdgeType.flat : (horizontalEdges[row - 1][col] == .inwards ? .outwards : .inwards)
                // El borde derecho es plano si está en el borde.
                let right = col == gridSize - 1 ? EdgeType.flat : verticalEdges[row][col]
                // El borde inferior es plano si está en el borde.
                let bottom = row == gridSize - 1 ? EdgeType.flat : horizontalEdges[row][col]
                // El borde izquierdo es el borde derecho de la pieza de la izquierda, o plano si está en el borde.
                let left = col == 0 ? EdgeType.flat : (verticalEdges[row][col - 1] == .inwards ? .outwards : .inwards)

                shapes.append(PuzzlePieceShape(top: top, right: right, bottom: bottom, left: left))
            }
        }
        return shapes
    }

    func placePiece(_ piece: PuzzlePiece, at index: Int) {
        if board[index] == nil {
            board[index] = piece
            pieces.removeAll { $0.id == piece.id }
            checkIfSolved()
        }
    }

    func returnPiece(at index: Int) {
        guard let pieceToReturn = board[index] else { return }
        board[index] = nil
        pieces.append(pieceToReturn)
        if isSolved {
            isSolved = false
        }
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

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: viewModel.gridSize)

        VStack {
            HStack {
                Text("Tiempo: \(Score(playerName: "", timeInSeconds: viewModel.elapsedTime, mode: .puzzle, totalItems: 0, puzzleGridSize: nil).displayTime)")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
            }

            Text("Completa el Puzzle")
                .font(.title)
                .padding()

            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(0..<viewModel.board.count, id: \.self) { index in
                    if let piece = viewModel.board[index] {
                        Image(uiImage: piece.image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(piece.shape)
                            .onTapGesture {
                                viewModel.returnPiece(at: index)
                            }
                    } else {
                        // Dibujar el contorno de la pieza que falta
                        if !viewModel.originalPieces.isEmpty {
                            viewModel.originalPieces[index].shape
                                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                                .background(Color.gray.opacity(0.15))
                                .aspectRatio(1, contentMode: .fit)
                                .onDrop(of: [.text], isTargeted: nil) { providers, _ in
                                    handleDrop(providers: providers, index: index)
                                }
                        }
                    }
                }
            }
            .padding()

            Spacer()

            if !viewModel.pieces.isEmpty && !viewModel.isSolved {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.pieces) { piece in
                            Image(uiImage: piece.image)
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(piece.shape)
                                .onDrag {
                                    NSItemProvider(object: piece.id.uuidString as NSString)
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Puzzle")
        .onChange(of: viewModel.isSolved) { isSolved in
            if isSolved {
                showingGameOver = true
            }
        }
        .sheet(isPresented: $showingGameOver) {
            // Pasamos `rankingManager` desde el entorno
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

    private func handleDrop(providers: [NSItemProvider], index: Int) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            guard let data = data as? Data, let pieceIdString = String(data: data, encoding: .utf8) else { return }

            DispatchQueue.main.async {
                if let pieceToMove = viewModel.pieces.first(where: { $0.id.uuidString == pieceIdString }) {
                    viewModel.placePiece(pieceToMove, at: index)
                }
            }
        }
        return true
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

    init() {
        self.numberOfPairs = UserDefaults.standard.object(forKey: "numberOfPairs") as? Int ?? 10
        self.showMatchedCards = UserDefaults.standard.object(forKey: "showMatchedCards") as? Bool ?? false
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true
        self.numberOfOperations = UserDefaults.standard.object(forKey: "numberOfOperations") as? Int ?? 4
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
