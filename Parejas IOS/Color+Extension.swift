import SwiftUI

extension Color {
    // Función clave: Convierte el nombre del color (String) a un objeto Color
    static func from(colorName: String) -> Color {
        switch colorName {
        case "Rojo":
            return .red
        case "Azul":
            return .blue
        case "Verde":
            return .green
        case "Amarillo":
            return .yellow
        case "Naranja":
            return .orange
        case "Morado":
            return .purple
        case "Rosa":
            return .pink
        case "Cian":
            // Cian no es un color estándar de SwiftUI, usamos 'Teal' o un valor RGB:
            return Color(red: 0, green: 1.0, blue: 1.0)
        case "Lima":
            return Color(red: 0.76, green: 1.0, blue: 0.0)
        case "Marrón":
            return .brown
        case "Gris":
            return .gray
        case "Negro":
            return .black
        case "Blanco":
            return .white
        case "Dorado":
            return .yellow.opacity(0.8) // Simulación
        case "Plata":
            return Color(white: 0.75) // Simulación
        case "Violeta":
            return Color(red: 0.56, green: 0.35, blue: 0.95)
        case "Turquesa":
            return Color(red: 0.25, green: 0.88, blue: 0.82)
        case "Coral":
            return Color(red: 1.0, green: 0.5, blue: 0.31)
        case "Oliva":
            return Color(red: 0.5, green: 0.5, blue: 0)
        case "Beige":
            return Color(red: 0.96, green: 0.96, blue: 0.86)
        default:
            // Color por defecto si no se encuentra
            return .clear
        }
    }
}
