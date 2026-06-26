import Foundation

typealias EntityID = UUID

struct UserGoal: Codable, Identifiable, Equatable {
    var id: EntityID
    var currentScore: Int
    var targetScore: Int
    var examDate: Date
    var dailyStudyMinutes: Int
    var weakParts: [TOEICPart]
    var createdAt: Date
    var updatedAt: Date
}

struct Material: Codable, Identifiable, Equatable {
    var id: EntityID
    var title: String
    var type: MaterialType
    var targetParts: [TOEICPart]
    var totalUnits: Int
    var completedUnits: Int
    var reviewCount: Int
    var createdAt: Date
    var updatedAt: Date
}

struct StudyLog: Codable, Identifiable, Equatable {
    var id: EntityID
    var studiedOn: Date
    var materialID: EntityID?
    var part: TOEICPart
    var minutes: Int
    var questionCount: Int?
    var correctCount: Int?
    var understanding: UnderstandingLevel
    var mistakeReasonIDs: [EntityID]
    var memo: String?
    var createdAt: Date
    var updatedAt: Date
}

struct MistakeReason: Codable, Identifiable, Equatable {
    var id: EntityID
    var category: MistakeReasonCategory
    var title: String
    var detail: String?
    var createdAt: Date
    var updatedAt: Date
}

struct VocabularyItem: Codable, Identifiable, Equatable {
    var id: EntityID
    var term: String
    var meaning: String
    var partOfSpeech: String?
    var example: String?
    var sourceMaterialID: EntityID?
    var createdAt: Date
    var updatedAt: Date
}

struct VocabularyCheckResult: Codable, Identifiable, Equatable {
    var id: EntityID
    var vocabularyItemID: EntityID
    var checkedAt: Date
    var rating: VocabularyRating
}

struct WeaknessNote: Codable, Identifiable, Equatable {
    var id: EntityID
    var title: String
    var part: TOEICPart
    var mistakeReasonID: EntityID?
    var body: String
    var relatedStudyLogIDs: [EntityID]
    var createdAt: Date
    var updatedAt: Date
}

struct AppData: Codable, Equatable {
    var userGoal: UserGoal?
    var materials: [Material]
    var studyLogs: [StudyLog]
    var mistakeReasons: [MistakeReason]
    var vocabularyItems: [VocabularyItem]
    var vocabularyCheckResults: [VocabularyCheckResult]
    var weaknessNotes: [WeaknessNote]

    static let empty = AppData(
        userGoal: nil,
        materials: [],
        studyLogs: [],
        mistakeReasons: [],
        vocabularyItems: [],
        vocabularyCheckResults: [],
        weaknessNotes: []
    )
}
