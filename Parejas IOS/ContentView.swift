// ContentView.swift
import SwiftUI
// Si GameViewModel, GameView, o GameMode están en un módulo o archivo separado,
// generalmente no necesitas importaciones adicionales aquí,
// pero asegúrate de que GameView, GameViewModel, y GameMode sean accesibles.



// ContentView.swift
struct ContentView: View {
    @StateObject var rankingManager = RankingManager()
    @StateObject var settingsManager = SettingsManager()
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingOperationSelection = false
    @State private var selectedGameMode: GameMode?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Juego de Parejas 🧠")
                    .font(.largeTitle).bold()
                
                Divider()
                
                ForEach(GameMode.allCases, id: \.self) { mode in
                    if mode == .matematicas {
                        Button(action: {
                            selectedGameMode = mode
                            showingOperationSelection = true
                        }) {
                            Text("Modo \(mode.rawValue)")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        NavigationLink(destination:
                            // Envuelve el destino en una ZStack. Esto es un truco conocido de SwiftUI.
                            ZStack {
                                GameView(viewModel: GameViewModel(mode: mode, settings: settingsManager), rankingManager: rankingManager)
                            }
                        ) {
                            Text("Modo \(mode.rawValue)")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                Divider()
                
                NavigationLink(destination: RankingView(rankingManager: rankingManager)) {
                    Text("🏆 Ver Top 10 Ranking")
                        .font(.title2).bold()
                        .padding()
                        .foregroundColor(.blue)
                }

                NavigationLink(destination: OptionsView(settings: settingsManager)) {
                    Text("⚙️ Opciones")
                        .font(.title2).bold()
                        .padding()
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationTitle("Menú Principal")
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
            OperationSelectionView(settings: settingsManager)
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
                    NavigationLink(destination: MathGameView(viewModel: MathViewModel(settings: settings, operations: selectedOperations))) {
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

    init(settings: SettingsManager, operations: Set<OperationType>) {
        self.settings = settings
        self.operations = Array(operations)
        self.remainingOperations = settings.numberOfOperations
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
    }
}
