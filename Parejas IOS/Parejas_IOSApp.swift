//
//  Parejas_IOSApp.swift
//  Parejas IOS
//
//  Created by brus on 13/11/25.
//

import SwiftUI
import AVFoundation

// Manager para controlar la reproducción de audio de fondo.
class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    init() {
        if let soundURL = Bundle.main.url(forResource: "pajaros", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Bucle infinito
            } catch {
                print("No se pudo cargar el archivo de sonido: \(error)")
            }
        }
    }

    func play() {
        audioPlayer?.play()
    }

    func pause() {
        audioPlayer?.pause()
    }
}

@main
struct Parejas_IOSApp: App {
    @StateObject private var audioManager = AudioManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
        }
    }
}
