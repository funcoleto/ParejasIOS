import SwiftUI

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
        let tabHeight = rect.width * 0.2 // Tamaño de la pestaña (20% del ancho)
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
