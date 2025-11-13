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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Juego de Parejas 🧠")
                    .font(.largeTitle).bold()
                
                Divider()
                
                ForEach(GameMode.allCases, id: \.self) { mode in
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

    init() {
        self.numberOfPairs = UserDefaults.standard.object(forKey: "numberOfPairs") as? Int ?? 10
        self.showMatchedCards = UserDefaults.standard.object(forKey: "showMatchedCards") as? Bool ?? false
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true
    }
}

struct OptionsView: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        Form {
            Section(header: Text("Configuración del Juego")) {
                Stepper(value: $settings.numberOfPairs, in: 2...20) {
                    Text("Número de Parejas: \(settings.numberOfPairs)")
                }

                Toggle(isOn: $settings.showMatchedCards) {
                    Text("Mostrar Cartas Emparejadas")
                }

                Toggle(isOn: $settings.isMusicEnabled) {
                    Text("Música de Fondo")
                }
            }
        }
        .navigationTitle("Opciones")
    }
}
