struct MusicalKey: Equatable {
    let tonic: PitchClass

    var name: String {
        "\(tonic.displayName) major"
    }
}
