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

            // Selector de imagen
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

            // Selector de dificultad
            Stepper("Tamaño de la cuadrícula: \(gridSize)x\(gridSize)", value: $gridSize, in: 3...10)
                .padding(.horizontal)

            // Botón para empezar a jugar
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

/// Representa una única pieza del puzzle.
struct PuzzlePiece: Identifiable, Equatable {
    let id = UUID()
    /// La imagen recortada para esta pieza.
    let image: UIImage
    /// El índice original de la pieza en la cuadrícula, para saber si está en la posición correcta.
    let originalIndex: Int
}

/// Gestiona la lógica del juego de puzzle.
class PuzzleViewModel: ObservableObject {
    /// Las piezas que aún no se han colocado en el tablero.
    @Published var pieces: [PuzzlePiece] = []
    @Published var board: [PuzzlePiece?]
    @Published var isSolved: Bool = false

    let gridSize: Int

    init(image: UIImage, gridSize: Int) {
        self.gridSize = gridSize
        self.board = Array(repeating: nil, count: gridSize * gridSize)
        self.pieces = self.sliceImage(image: image, gridSize: gridSize)
    }

    private func sliceImage(image: UIImage, gridSize: Int) -> [PuzzlePiece] {
        guard let cgImage = image.cgImage else { return [] }

        let pieceWidth = CGFloat(cgImage.width) / CGFloat(gridSize)
        let pieceHeight = CGFloat(cgImage.height) / CGFloat(gridSize)
        var slicedPieces: [PuzzlePiece] = []

        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let rect = CGRect(x: CGFloat(x) * pieceWidth, y: CGFloat(y) * pieceHeight, width: pieceWidth, height: pieceHeight)
                if let slicedCGImage = cgImage.cropping(to: rect) {
                    let uiImage = UIImage(cgImage: slicedCGImage, scale: image.scale, orientation: image.imageOrientation)
                    let piece = PuzzlePiece(image: uiImage, originalIndex: y * gridSize + x)
                    slicedPieces.append(piece)
                }
            }
        }
        return slicedPieces.shuffled()
    }

    func placePiece(_ piece: PuzzlePiece, at index: Int) {
        if board[index] == nil {
            board[index] = piece
            pieces.removeAll { $0.id == piece.id }
            checkIfSolved()
        }
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
        }
    }
}

/// La vista principal del juego de puzzle, que muestra el tablero y las piezas arrastrables.
struct PuzzleGameView: View {
    @StateObject var viewModel: PuzzleViewModel

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: viewModel.gridSize)

        VStack {
            if viewModel.isSolved {
                Text("¡Puzzle Resuelto!")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .padding()
            } else {
                Text("Completa el Puzzle")
                    .font(.title)
                    .padding()
            }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<viewModel.board.count, id: \.self) { index in
                    if let piece = viewModel.board[index] {
                        Image(uiImage: piece.image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .onDrop(of: [.text], isTargeted: nil) { providers, _ in
                                handleDrop(providers: providers, index: index)
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
                                .cornerRadius(5)
                                .onDrag { NSItemProvider(object: piece.id.uuidString as NSString) }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Puzzle")
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


// Helper para el selector de imágenes de UIKit
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
                    if mode == .matematicas {
                        Button(action: {
                            selectedGameMode = mode
                            showingOperationSelection = true
                        }) {
                            Text("Modo \(mode.rawValue)")
                                .font(.title2)
                                .frame(maxWidth: 300)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        NavigationLink(destination:
                            ZStack {
                                GameView(viewModel: GameViewModel(mode: mode, settings: settingsManager), rankingManager: rankingManager)
                            }
                        ) {
                            Text("Modo \(mode.rawValue)")
                                .font(.title2)
                                .frame(maxWidth: 300)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else if mode == .puzzle {
                        // Botón para el nuevo modo Puzzle
                        NavigationLink(destination: PuzzleSetupView()) {
                            Text("Modo \(mode.rawValue)")
                                .font(.title2)
                                .frame(maxWidth: 300)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
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
}

// Vista para el juego de matemáticas
struct MathGameView: View {
    @ObservedObject var viewModel: MathViewModel
    @ObservedObject var rankingManager: RankingManager
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isGameOver {
                Text("¡Juego Terminado!")
                    .font(.largeTitle)
                Text("Tu puntuación: \(viewModel.score) / \(viewModel.settings.numberOfOperations)")
                    .font(.title)
                Button("Volver al Menú") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            } else {
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
        }
        .navigationTitle("Matemáticas")
        .onChange(of: viewModel.isGameOver) { isGameOver in
            if isGameOver {
                let newScore = Score(
                    playerName: "Jugador", // Nombre de jugador temporal
                    timeInSeconds: 0, // No aplica para este modo
                    mode: .matematicas,
                    numberOfPairs: 0, // No aplica
                    mathScore: viewModel.score
                )
                rankingManager.saveScore(newScore: newScore)
            }
        }
    }
}
