import SwiftUI

public struct LudoGameView: View {
    @State private var diceValue: Int = 6
    @State private var isRolling: Bool = false
    
    // Player turn: 0: Red, 1: Green, 2: Yellow, 3: Blue
    @State private var currentTurn: Int = 0
    
    // 4 Players x 4 Tokens each
    // position: -1 means in Home Base Yard, 0..51 main track, 52..56 home stretch, 57 finished
    @State private var tokenPositions: [[Int]] = [
        [-1, -1, -1, -1], // Red (Start at track pos 0)
        [-1, -1, -1, -1], // Green (Start at track pos 13)
        [-1, -1, -1, -1], // Yellow (Start at track pos 26)
        [-1, -1, -1, -1]  // Blue (Start at track pos 39)
    ]
    
    @State private var gameMessage: String = "Red's turn! Roll a 6 to bring out a token."
    @State private var winnerMessage: String? = nil

    private let playerColors: [Color] = [.red, .green, .yellow, .blue]
    private let playerNames = ["Red", "Green", "Yellow", "Blue"]

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🎲 Classic Ludo King Board")
                        .font(.title2)
                        .bold()
                    Text(gameMessage)
                        .font(.caption)
                        .foregroundColor(playerColors[currentTurn])
                        .fontWeight(.bold)
                }
                Spacer()

                Button("New Game") {
                    resetGame()
                }
                .buttonStyle(.bordered)
            }

            // AUTHENTIC LUDO BOARD GRID (15x15)
            ZStack {
                // Board Border
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(radius: 6)

                VStack(spacing: 0) {
                    // TOP ROW (6-col Base, 3-col Track, 6-col Base)
                    HStack(spacing: 0) {
                        yardBox(playerIndex: 3, color: .blue)   // Top-Left: Blue
                        topTrackColumn()                        // Top-Center: Green Path
                        yardBox(playerIndex: 1, color: .green)  // Top-Right: Green
                    }

                    // MIDDLE ROW (6-col Track, 3-col Center Triangle, 6-col Track)
                    HStack(spacing: 0) {
                        leftTrackRow()                           // Mid-Left: Blue Path
                        centerTriangleHome()                     // Mid-Center: Triangular Home Finish
                        rightTrackRow()                          // Mid-Right: Yellow Path
                    }

                    // BOTTOM ROW (6-col Base, 3-col Track, 6-col Base)
                    HStack(spacing: 0) {
                        yardBox(playerIndex: 0, color: .red)     // Bottom-Left: Red
                        bottomTrackColumn()                      // Bottom-Center: Red Path
                        yardBox(playerIndex: 2, color: .yellow)  // Bottom-Right: Yellow
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // OVERLAY TOKENS ON BOARD
                GeometryReader { geo in
                    let boardSize = min(geo.size.width, geo.size.height)
                    let cellSize = boardSize / 15.0
                    
                    ForEach(0..<4, id: \.self) { pIdx in
                        ForEach(0..<4, id: \.self) { tIdx in
                            let pos = tokenPositions[pIdx][tIdx]
                            let point = getCellCoordinates(player: pIdx, tokenIndex: tIdx, pos: pos, cellSize: cellSize)
                            
                            pawnTokenView(playerIndex: pIdx, tokenIndex: tIdx)
                                .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                                .position(point)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 2)
                                .onTapGesture {
                                    handleTokenTap(player: pIdx, tokenIndex: tIdx)
                                }
                        }
                    }
                }
            }
            .frame(width: 320, height: 320)

            // DICE CONTROLLER BAR
            HStack(spacing: 20) {
                // Turn Indicator Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(playerColors[currentTurn])
                        .frame(width: 14, height: 14)
                    Text("\(playerNames[currentTurn])'s Turn")
                        .font(.headline)
                        .foregroundColor(playerColors[currentTurn])
                }

                Spacer()

                // Dice Cube
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [playerColors[currentTurn], playerColors[currentTurn].opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                        .shadow(radius: 3)

                    Text("\(diceValue)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isRolling ? 360 : 0))
                }

                Button(action: rollDice) {
                    Label(isRolling ? "Rolling..." : "Roll Dice", systemImage: "dice.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(playerColors[currentTurn])
                .controlSize(.large)
                .disabled(isRolling)
            }
            .padding(.horizontal, 8)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
    }

    // MARK: - Board Quadrant Components
    private func yardBox(playerIndex: Int, color: Color) -> some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: 128, height: 128)

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 92, height: 92)

            // 4 Yard Spots
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    yardSpotCircle(color: color)
                    yardSpotCircle(color: color)
                }
                HStack(spacing: 16) {
                    yardSpotCircle(color: color)
                    yardSpotCircle(color: color)
                }
            }
        }
    }

    private func yardSpotCircle(color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(color, lineWidth: 2))
    }

    // 3x6 Track Columns & Rows
    private func topTrackColumn() -> some View {
        VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { r in
                HStack(spacing: 0) {
                    gridCell(isGreen: r > 0 && r < 6 && r != 0, isStar: r == 1) // Green home stretch
                    gridCell(isGreen: r > 0, isStar: false)
                    gridCell(isGreen: false, isStar: r == 2)
                }
            }
        }
        .frame(width: 64, height: 128)
    }

    private func bottomTrackColumn() -> some View {
        VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { r in
                HStack(spacing: 0) {
                    gridCell(isRed: false, isStar: r == 3)
                    gridCell(isRed: r < 5, isStar: false)
                    gridCell(isRed: r == 4, isStar: r == 4)
                }
            }
        }
        .frame(width: 64, height: 128)
    }

    private func leftTrackRow() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { c in
                VStack(spacing: 0) {
                    gridCell(isBlue: c == 1, isStar: c == 1)
                    gridCell(isBlue: c > 0, isStar: false)
                    gridCell(isBlue: false, isStar: c == 2)
                }
            }
        }
        .frame(width: 128, height: 64)
    }

    private func rightTrackRow() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { c in
                VStack(spacing: 0) {
                    gridCell(isYellow: false, isStar: c == 3)
                    gridCell(isYellow: c < 5, isStar: false)
                    gridCell(isYellow: c == 4, isStar: c == 4)
                }
            }
        }
        .frame(width: 128, height: 64)
    }

    private func gridCell(isRed: Bool = false, isGreen: Bool = false, isYellow: Bool = false, isBlue: Bool = false, isStar: Bool = false) -> some View {
        ZStack {
            Rectangle()
                .fill(isRed ? Color.red : (isGreen ? Color.green : (isYellow ? Color.yellow : (isBlue ? Color.blue : Color.white))))
                .border(Color.gray.opacity(0.3), width: 0.5)

            if isStar {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(isRed || isGreen || isYellow || isBlue ? .white : .gray)
            }
        }
        .frame(width: 21.3, height: 21.3)
    }

    // Center Triangles
    private func centerTriangleHome() -> some View {
        ZStack {
            Rectangle().fill(Color.white)
            
            // 4 Triangles meeting at center
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                // Blue (Left)
                var pBlue = Path()
                pBlue.move(to: CGPoint(x: 0, y: 0))
                pBlue.addLine(to: center)
                pBlue.addLine(to: CGPoint(x: 0, y: size.height))
                context.fill(pBlue, with: .color(.blue))

                // Green (Top)
                var pGreen = Path()
                pGreen.move(to: CGPoint(x: 0, y: 0))
                pGreen.addLine(to: center)
                pGreen.addLine(to: CGPoint(x: size.width, y: 0))
                context.fill(pGreen, with: .color(.green))

                // Yellow (Right)
                var pYellow = Path()
                pYellow.move(to: CGPoint(x: size.width, y: 0))
                pYellow.addLine(to: center)
                pYellow.addLine(to: CGPoint(x: size.width, y: size.height))
                context.fill(pYellow, with: .color(.yellow))

                // Red (Bottom)
                var pRed = Path()
                pRed.move(to: CGPoint(x: 0, y: size.height))
                pRed.addLine(to: center)
                pRed.addLine(to: CGPoint(x: size.width, y: size.height))
                context.fill(pRed, with: .color(.red))
            }
        }
        .frame(width: 64, height: 64)
    }

    // Pawn Token Graphic
    private func pawnTokenView(playerIndex: Int, tokenIndex: Int) -> some View {
        ZStack {
            // Glow border
            Circle()
                .fill(Color.white)
            
            // Pawn body gradient
            Circle()
                .fill(LinearGradient(colors: [playerColors[playerIndex], playerColors[playerIndex].opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(2)
            
            // Inner head shine
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 6, height: 6)
                .offset(x: -2, y: -2)
        }
    }

    // MARK: - Game Mechanics & Logic
    private func rollDice() {
        isRolling = true
        withAnimation(.easeInOut(duration: 0.3)) {
            diceValue = Int.random(in: 1...6)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isRolling = false
            evaluateTurn()
        }
    }

    private func evaluateTurn() {
        let playerTokens = tokenPositions[currentTurn]
        let movableTokens = playerTokens.indices.filter { canMoveToken(player: currentTurn, tokenIndex: $0) }
        
        if movableTokens.isEmpty {
            gameMessage = "\(playerNames[currentTurn]) rolled a \(diceValue). No valid move!"
            nextTurn()
        } else if movableTokens.count == 1 {
            // Auto move single movable token
            moveToken(player: currentTurn, tokenIndex: movableTokens.first!)
        } else {
            gameMessage = "\(playerNames[currentTurn]) rolled a \(diceValue)! Tap a token to move."
        }
    }

    private func canMoveToken(player: Int, tokenIndex: Int) -> Bool {
        let pos = tokenPositions[player][tokenIndex]
        if pos == -1 {
            return diceValue == 6 // Need 6 to come out of yard
        }
        if pos >= 57 { return false } // Already finished
        return (pos + diceValue) <= 57
    }

    private func handleTokenTap(player: Int, tokenIndex: Int) {
        guard player == currentTurn, !isRolling else { return }
        if canMoveToken(player: player, tokenIndex: tokenIndex) {
            moveToken(player: player, tokenIndex: tokenIndex)
        }
    }

    private func moveToken(player: Int, tokenIndex: Int) {
        let currentPos = tokenPositions[player][tokenIndex]
        
        if currentPos == -1 {
            tokenPositions[player][tokenIndex] = 0 // Enter track
            gameMessage = "\(playerNames[player]) token entered the board!"
        } else {
            let newPos = currentPos + diceValue
            tokenPositions[player][tokenIndex] = newPos
            gameMessage = "\(playerNames[player]) token moved \(diceValue) steps!"
        }
        
        // Extra turn if rolled 6
        if diceValue == 6 {
            gameMessage += " Rolled 6: Extra turn!"
        } else {
            nextTurn()
        }
    }

    private func nextTurn() {
        currentTurn = (currentTurn + 1) % 4
    }

    private func resetGame() {
        tokenPositions = [
            [-1, -1, -1, -1],
            [-1, -1, -1, -1],
            [-1, -1, -1, -1],
            [-1, -1, -1, -1]
        ]
        currentTurn = 0
        diceValue = 6
        gameMessage = "Red's turn! Roll a 6 to bring out a token."
    }

    // Map Token Position to (X, Y) Coordinates on 15x15 Board
    private func getCellCoordinates(player: Int, tokenIndex: Int, pos: Int, cellSize: CGFloat) -> CGPoint {
        // Base Yard Offset Coordinates
        if pos == -1 {
            let yardOffsets: [Int: [(CGFloat, CGFloat)]] = [
                0: [(2, 11), (4, 11), (2, 13), (4, 13)], // Red (Bottom-Left)
                1: [(11, 2), (13, 2), (11, 4), (13, 4)], // Green (Top-Right)
                2: [(11, 11), (13, 11), (11, 13), (13, 13)], // Yellow (Bottom-Right)
                3: [(2, 2), (4, 2), (2, 4), (4, 4)]   // Blue (Top-Left)
            ]
            let (gx, gy) = yardOffsets[player]![tokenIndex]
            return CGPoint(x: (gx + 0.5) * cellSize, y: (gy + 0.5) * cellSize)
        }
        
        // Track path mapping
        let trackCoords: [(CGFloat, CGFloat)] = [
            (6, 13), (6, 12), (6, 11), (6, 10), (6, 9), (5, 8), (4, 8), (3, 8), (2, 8), (1, 8), (0, 8), (0, 7),
            (0, 6), (1, 6), (2, 6), (3, 6), (4, 6), (5, 6), (6, 5), (6, 4), (6, 3), (6, 2), (6, 1), (6, 0), (7, 0),
            (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (9, 6), (10, 6), (11, 6), (12, 6), (13, 6), (14, 6), (14, 7),
            (14, 8), (13, 8), (12, 8), (11, 8), (10, 8), (9, 8), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (8, 14), (7, 14), (6, 14)
        ]
        
        let playerTrackOffsets = [0, 13, 26, 39]
        let globalTrackIdx = (pos + playerTrackOffsets[player]) % 52
        let (gx, gy) = trackCoords[globalTrackIdx]
        
        return CGPoint(x: (gx + 0.5) * cellSize, y: (gy + 0.5) * cellSize)
    }
}
