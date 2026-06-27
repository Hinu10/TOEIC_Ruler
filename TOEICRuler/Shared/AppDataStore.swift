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

    func saveStudyLog(_ studyLog: StudyLog) throws {
        var nextData = appData
        if let index = nextData.studyLogs.firstIndex(where: { $0.id == studyLog.id }) {
            nextData.studyLogs[index] = studyLog
        } else {
            nextData.studyLogs.append(studyLog)
        }
        nextData.studyLogs.sort { $0.studiedOn > $1.studiedOn }
        try persist(nextData)
    }

    func deleteStudyLog(_ studyLog: StudyLog) throws {
        var nextData = appData
        nextData.studyLogs.removeAll { $0.id == studyLog.id }
        nextData.mistakeReasons.removeAll { $0.studyLogID == studyLog.id }
        try persist(nextData)
    }

    func saveMistakeReason(_ mistakeReason: MistakeReason) throws {
        var nextData = appData
        if let index = nextData.mistakeReasons.firstIndex(where: { $0.id == mistakeReason.id }) {
            nextData.mistakeReasons[index] = mistakeReason
        } else {
            nextData.mistakeReasons.insert(mistakeReason, at: 0)
        }
        try persist(nextData)
    }

    private func persist(_ nextData: AppData) throws {
        try localStore.save(nextData)
        appData = nextData
    }
}
