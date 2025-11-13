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
    @Published var currentOperation: (String, Int)? = nil
    @Published var userAnswer: String = ""
    @Published var score: Int = 0
    @Published var remainingOperations: Int
    @Published var isGameOver: Bool = false

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
        var question: String
        var answer: Int

        switch operationType {
        case .suma:
            let a = Int.random(in: 1...20)
            let b = Int.random(in: 1...20)
            question = "\(a) + \(b) ="
            answer = a + b
        case .resta:
            let a = Int.random(in: 10...30)
            let b = Int.random(in: 1...a)
            question = "\(a) - \(b) ="
            answer = a - b
        case .multiplicacion:
            let a = Int.random(in: 2...10)
            let b = Int.random(in: 2...10)
            question = "\(a) x \(b) ="
            answer = a * b
        case .division:
            let b = Int.random(in: 2...10)
            answer = Int.random(in: 2...10)
            let a = b * answer
            question = "\(a) ÷ \(b) ="
        }
        currentOperation = (question, answer)
    }

    func submitAnswer() {
        guard let correctAnswer = currentOperation?.1 else { return }

        if Int(userAnswer) == correctAnswer {
            score += 1
        }

        remainingOperations -= 1
        userAnswer = ""

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
                Button("Jugar de Nuevo") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            } else {
                Text("Operaciones Restantes: \(viewModel.remainingOperations)")
                    .font(.headline)

                if let operation = viewModel.currentOperation {
                    Text(operation.0)
                        .font(.largeTitle)
                }

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
    }
}
