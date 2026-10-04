import SwiftUI

public struct CarParkingGameView: View {
    @State private var carX: CGFloat = 120
    @State private var carY: CGFloat = 170
    @State private var carRotation: Double = 0
    @State private var isParked: Bool = false
    @State private var collisionsCount: Int = 0
    @State private var parkingScore: Int = 0

    // Parking Spot Location & Boundary
    private let spotRect = CGRect(x: 230, y: 35, width: 75, height: 110)

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🚗 Mac Car Parking Simulation")
                        .font(.title2)
                        .bold()
                    Text("Steer & align your car into the yellow parking bay!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(isParked ? "PARKED PERFECTLY! 🏆" : "Collisions: \(collisionsCount)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(isParked ? .green : (collisionsCount > 0 ? .red : .primary))
                    Text("Score: \(parkingScore) pts")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Interactive Asphalt Parking Lot Arena
            ZStack {
                // Asphalt Base
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .darkGray))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )

                // Parking Bay Striping (Yellow Zone)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isParked ? Color.green : Color.yellow, style: StrokeStyle(lineWidth: 3, dash: [6]))
                        .background(isParked ? Color.green.opacity(0.3) : Color.yellow.opacity(0.12))
                        .frame(width: spotRect.width, height: spotRect.height)

                    VStack(spacing: 4) {
                        Image(systemName: isParked ? "checkmark.seal.fill" : "parkingticket.fill")
                            .font(.title2)
                            .foregroundColor(isParked ? .green : .yellow)
                        Text(isParked ? "SUCCESS" : "RESERVED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isParked ? .green : .yellow)
                    }
                }
                .position(x: spotRect.midX, y: spotRect.midY)

                // Concrete Wall Obstacle 1
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.85))
                        .overlay(
                            Text("🚧 CONCRETE BARRIER 🚧")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 110, height: 22)
                .position(x: 90, y: 90)

                // Concrete Wall Obstacle 2
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.85))
                }
                .frame(width: 22, height: 80)
                .position(x: 170, y: 170)

                // Player Sports Car Graphic
                ZStack {
                    // Car Body
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 36, height: 64)
                        .shadow(radius: 4)

                    // Windshield & Roof
                    VStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 26, height: 14)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 26, height: 12)
                            .cornerRadius(2)
                    }
                    
                    // Headlights
                    HStack(spacing: 20) {
                        Circle().fill(Color.yellow).frame(width: 5, height: 5)
                        Circle().fill(Color.yellow).frame(width: 5, height: 5)
                    }
                    .offset(y: -28)
                }
                .rotationEffect(.degrees(carRotation))
                .position(x: carX, y: carY)
            }
            .frame(height: 240)

            // Vehicle Dashboard & Controls
            HStack(spacing: 20) {
                // Steering Wheel Rotators
                VStack(spacing: 4) {
                    Text("STEERING")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        Button(action: { steer(-15) }) {
                            Image(systemName: "rotate.left.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)

                        Button(action: { steer(15) }) {
                            Image(systemName: "rotate.right.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()

                // Accelerator / Reverser Controls
                VStack(spacing: 4) {
                    Text("DRIVE / REVERSE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Button(action: { moveCar(distance: -14) }) {
                            Label("DRIVE", systemImage: "arrow.up.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button(action: { moveCar(distance: 14) }) {
                            Label("REVERSE", systemImage: "arrow.down.circle.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()

                Button("Reset Position") {
                    carX = 120
                    carY = 170
                    carRotation = 0
                    isParked = false
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
    }

    private func steer(_ angle: Double) {
        withAnimation(.easeInOut(duration: 0.1)) {
            carRotation += angle
        }
        checkParkingStatus()
    }

    private func moveCar(distance: CGFloat) {
        let radians = carRotation * .pi / 180.0
        withAnimation(.easeInOut(duration: 0.1)) {
            carX += sin(radians) * distance
            carY -= cos(radians) * distance
        }
        checkParkingStatus()
    }

    private func checkParkingStatus() {
        let carRect = CGRect(x: carX - 18, y: carY - 32, width: 36, height: 64)
        
        // Check barrier collisions
        let barrier1 = CGRect(x: 35, y: 79, width: 110, height: 22)
        let barrier2 = CGRect(x: 159, y: 130, width: 22, height: 80)
        
        if carRect.intersects(barrier1) || carRect.intersects(barrier2) {
            collisionsCount += 1
            // Bounce back safely
            carY += 16
        }

        // Check if aligned inside spot
        if spotRect.contains(CGPoint(x: carX, y: carY)) {
            if !isParked {
                isParked = true
                parkingScore += 100
            }
        } else {
            isParked = false
        }
    }
}
