import XCTest
@testable import Parejas_IOS

class RankingManagerTests: XCTestCase {

    var rankingManager: RankingManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        rankingManager = RankingManager()
        // Limpiar UserDefaults antes de cada prueba
        UserDefaults.standard.removeObject(forKey: "MemoryGameTopScores")
        rankingManager.allScores = []
    }

    override func tearDownWithError() throws {
        rankingManager = nil
        UserDefaults.standard.removeObject(forKey: "MemoryGameTopScores")
        try super.tearDownWithError()
    }

    func testSaveAndSortNormalScore() {
        // Arrange
        let score1 = Score(playerName: "Player1", timeInSeconds: 100, mode: .color, numberOfPairs: 8, mathScore: nil)
        let score2 = Score(playerName: "Player2", timeInSeconds: 50, mode: .color, numberOfPairs: 8, mathScore: nil)
        let score3 = Score(playerName: "Player3", timeInSeconds: 150, mode: .color, numberOfPairs: 8, mathScore: nil)

        // Act
        rankingManager.saveScore(newScore: score1)
        rankingManager.saveScore(newScore: score2)
        rankingManager.saveScore(newScore: score3)

        // Assert
        let topScores = rankingManager.getTop10(for: .color)
        XCTAssertEqual(topScores.count, 3)
        XCTAssertEqual(topScores[0].playerName, "Player2") // El más rápido primero
        XCTAssertEqual(topScores[1].playerName, "Player1")
        XCTAssertEqual(topScores[2].playerName, "Player3")
    }

    func testSaveAndSortMathScore() {
        // Arrange
        let score1 = Score(playerName: "MathWiz", timeInSeconds: 0, mode: .matematicas, numberOfPairs: 0, mathScore: 15)
        let score2 = Score(playerName: "MathPro", timeInSeconds: 0, mode: .matematicas, numberOfPairs: 0, mathScore: 20)
        let score3 = Score(playerName: "MathNewbie", timeInSeconds: 0, mode: .matematicas, numberOfPairs: 0, mathScore: 10)

        // Act
        rankingManager.saveScore(newScore: score1)
        rankingManager.saveScore(newScore: score2)
        rankingManager.saveScore(newScore: score3)

        // Assert
        let topScores = rankingManager.getTop10(for: .matematicas)
        XCTAssertEqual(topScores.count, 3)
        XCTAssertEqual(topScores[0].playerName, "MathPro") // La puntuación más alta primero
        XCTAssertEqual(topScores[1].playerName, "MathWiz")
        XCTAssertEqual(topScores[2].playerName, "MathNewbie")
    }

    func testTop10Limit() {
        // Arrange
        for i in 1...15 {
            let score = Score(playerName: "Player\(i)", timeInSeconds: Double(i * 10), mode: .letter, numberOfPairs: 10, mathScore: nil)
            rankingManager.saveScore(newScore: score)
        }

        // Act
        let topScores = rankingManager.getTop10(for: .letter)

        // Assert
        XCTAssertEqual(topScores.count, 10)
        XCTAssertEqual(topScores[0].playerName, "Player1") // El más rápido (menor tiempo)
    }
}
