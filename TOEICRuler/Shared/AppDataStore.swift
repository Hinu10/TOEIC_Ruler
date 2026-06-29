import Foundation

@MainActor
final class AppDataStore: ObservableObject {
    @Published private(set) var appData: AppData

    private let localStore: LocalAppDataStore

    init(localStore: LocalAppDataStore = .shared) {
        self.localStore = localStore
        appData = localStore.load()
    }

    func saveGoal(_ goal: UserGoal) throws {
        var nextData = appData
        nextData.userGoal = goal
        try persist(nextData)
    }

    func saveMaterial(_ material: Material) throws {
        var nextData = appData
        if let index = nextData.materials.firstIndex(where: { $0.id == material.id }) {
            nextData.materials[index] = material
        } else {
            nextData.materials.insert(material, at: 0)
        }
        try persist(nextData)
    }

    func deleteMaterial(_ material: Material) throws {
        var nextData = appData
        nextData.materials.removeAll { $0.id == material.id }
        try persist(nextData)
    }

    func saveWeaknessNote(_ note: WeaknessNote) throws {
        var nextData = appData
        if let index = nextData.weaknessNotes.firstIndex(where: { $0.id == note.id || $0.part == note.part }) {
            nextData.weaknessNotes[index] = note
        } else {
            nextData.weaknessNotes.insert(note, at: 0)
        }
        try persist(nextData)
    }

    func weaknessNote(for part: TOEICPart) -> WeaknessNote? {
        appData.weaknessNotes.first { $0.part == part }
    }

    private func persist(_ nextData: AppData) throws {
        try localStore.save(nextData)
        appData = nextData
    }
}
