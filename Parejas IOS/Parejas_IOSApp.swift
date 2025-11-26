//
//  Parejas_IOSApp.swift
//  Parejas IOS
//
//  Created by brus on 13/11/25.
//

import SwiftUI
import AVFoundation

// Manager para controlar la reproducción de audio de fondo.
class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [AVAudioPlayer] = []

    override init() {
        super.init()
        if let soundURL = Bundle.main.url(forResource: "pajaros", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: soundURL)
                backgroundMusicPlayer?.numberOfLoops = -1 // Bucle infinito
            } catch {
                print("No se pudo cargar el archivo de sonido de fondo: \(error)")
            }
        }
    }

    func play() {
        backgroundMusicPlayer?.play()
    }

    func pause() {
        backgroundMusicPlayer?.pause()
    }

    // Nueva función para reproducir efectos de sonido
    func playSoundEffect(named soundName: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("No se encontró el archivo de sonido: \(soundName).mp3")
            return
        }

        do {
            let soundEffectPlayer = try AVAudioPlayer(contentsOf: soundURL)
            soundEffectPlayer.delegate = self
            soundEffectPlayer.play()
            soundEffectPlayers.append(soundEffectPlayer)
        } catch {
            print("No se pudo reproducir el efecto de sonido: \(error)")
        }
    }

    // Delegado para limpiar los reproductores de efectos de sonido cuando terminan
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        soundEffectPlayers.removeAll { $0 == player }
    }
}

@main
struct Parejas_IOSApp: App {
    @StateObject private var audioManager = AudioManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView {
                        withAnimation {
                            showSplash = false
                        }
                    }
                } else {
                    ContentView()
                        .environmentObject(audioManager)
                        .transition(.opacity)
                }
            }
        }
    }
}
