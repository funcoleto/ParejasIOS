import SwiftUI

// La vista que representa una sola carta.
struct CardView: View {
    @ObservedObject var viewModel: GameViewModel
    let card: Card
    let settings: SettingsManager
    
    // Determina el color o la forma de visualización según el modo
    private var faceUpContent: some View {
        Group {
            switch card.mode {
            case .matematicas:
                EmptyView()
            case .puzzle:
                EmptyView()
            case .color:
                // AHORA USAMOS LA FUNCIÓN DE EXTENSIÓN
                Color.from(colorName: card.content)
                    .cornerRadius(5) // Para que el color no se extienda fuera de los bordes
                    .padding(5)     // Espaciado interno
            case .letter:
                let components = card.content.split(separator: "|")
                let uppercaseLetter = String(components.first ?? "?")
                let lowercaseLetter = String(components.last ?? "?")

                VStack(spacing: 5) {
                    Text(uppercaseLetter)
                        .font(.system(size: 35, weight: .heavy))
                    Text(lowercaseLetter)
                        .font(.system(size: 25, weight: .medium))
                }
                .foregroundColor(.black)
                    
            case .colorAndLetter:
                // 1. Separar los componentes: "A|a|Rojo"
                let components = card.content.split(separator: "|")
                let uppercaseLetter = String(components[0])
                let lowercaseLetter = String(components[1])
                let colorName = String(components[2])

                // 2. Crear el color de fondo
                let backgroundColor = Color.from(colorName: colorName)

                // 3. Apilar el contenido (letras) sobre el fondo de color
                ZStack {
                    backgroundColor
                        .cornerRadius(5)
                        .padding(5)

                    VStack(spacing: 5) {
                        Text(uppercaseLetter)
                            .font(.system(size: 35, weight: .heavy))
                        Text(lowercaseLetter)
                            .font(.system(size: 25, weight: .medium))
                    }
                    .foregroundColor(.white) // Letras en blanco para contraste
                }
            case .shapeAndColor:
                        // 1. Separar la figura y el color del contenido (ej: "star.fill|Rojo")
                        let components = card.content.split(separator: "|")
                        let shapeName = String(components.first ?? "questionmark.circle.fill")
                        let colorName = String(components.last ?? "Negro")
                        
                        // 2. Crear el objeto Color usando la extensión
                        let dynamicColor = Color.from(colorName: colorName)
                        
                        // 3. Renderizar la figura con el color
                        Image(systemName: shapeName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(dynamicColor) // Aplicar el color dinámico
                            .padding(10) // Padding interno para que no toque los bordes de la carta
            }
        }
    }
    
    var body: some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: 10)
            
            // La lógica de visibilidad ahora se controla en GameView
            if card.isFaceUp {
                // 2. Carta Boca Arriba (Muestra el contenido)
                shape.fill(.white)
                shape.strokeBorder(.gray, lineWidth: 3)
                faceUpContent
                    .padding()
            } else {
                // 3. Carta Boca Abajo (El reverso)
                shape.fill(.gray)
            }
        }
        // Animación de volteo (el efecto 3D es opcional pero mejora la experiencia)
        .rotation3DEffect(
            .degrees(card.isFaceUp ? 0 : 180),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        .animation(.default, value: card.isFaceUp)
    }
}
