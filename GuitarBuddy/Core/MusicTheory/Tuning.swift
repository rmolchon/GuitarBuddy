struct Tuning: Hashable {
    let name: String
    let stringFrequencies: [Double]

    static let standard = Tuning(name: "Standard", stringFrequencies: [82.41, 110.00, 146.83, 196.00, 246.94, 329.63])
    static let dropD = Tuning(name: "Drop D", stringFrequencies: [73.42, 110.00, 146.83, 196.00, 246.94, 329.63])
    static let openG = Tuning(name: "Open G", stringFrequencies: [73.42, 98.00, 146.83, 196.00, 246.94, 293.66])
    static let openD = Tuning(name: "Open D", stringFrequencies: [73.42, 110.00, 146.83, 185.00, 220.00, 293.66])
    static let dadgad = Tuning(name: "DADGAD", stringFrequencies: [73.42, 110.00, 146.83, 196.00, 220.00, 293.66])
    static let halfStepDown = Tuning(name: "Half-Step Down", stringFrequencies: [77.78, 103.83, 138.59, 185.00, 233.08, 311.13])

    static let allPresets: [Tuning] = [standard, dropD, openG, openD, dadgad, halfStepDown]
}
