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
    var name: String
    var type: MaterialType
    var targetParts: [TOEICPart]
    var currentRound: Int
    var targetRounds: Int
    var progressRate: Double
    var memo: String?
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
    var materialID: EntityID?
    var term: String
    var meaning: String
    var userMemo: String?
    var partOfSpeech: String?
    var sourceRange: String
    var round: Int
    var lastCheckedAt: Date?
    var latestResult: VocabularyRating?
    var sourceMaterialID: EntityID?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case materialID
        case term
        case meaning
        case userMemo
        case partOfSpeech
        case sourceRange
        case round
        case lastCheckedAt
        case latestResult
        case sourceMaterialID
        case createdAt
        case updatedAt
    }

    init(
        id: EntityID,
        materialID: EntityID?,
        term: String,
        meaning: String,
        userMemo: String?,
        partOfSpeech: String?,
        sourceRange: String,
        round: Int,
        lastCheckedAt: Date?,
        latestResult: VocabularyRating?,
        sourceMaterialID: EntityID?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.materialID = materialID
        self.term = term
        self.meaning = meaning
        self.userMemo = userMemo
        self.partOfSpeech = partOfSpeech
        self.sourceRange = sourceRange
        self.round = round
        self.lastCheckedAt = lastCheckedAt
        self.latestResult = latestResult
        self.sourceMaterialID = sourceMaterialID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(EntityID.self, forKey: .id)
        materialID = try container.decodeIfPresent(EntityID.self, forKey: .materialID)
            ?? container.decodeIfPresent(EntityID.self, forKey: .sourceMaterialID)
        term = try container.decode(String.self, forKey: .term)
        meaning = try container.decode(String.self, forKey: .meaning)
        userMemo = try container.decodeIfPresent(String.self, forKey: .userMemo)
        partOfSpeech = try container.decodeIfPresent(String.self, forKey: .partOfSpeech)
        sourceRange = try container.decodeIfPresent(String.self, forKey: .sourceRange) ?? ""
        round = try container.decodeIfPresent(Int.self, forKey: .round) ?? 1
        lastCheckedAt = try container.decodeIfPresent(Date.self, forKey: .lastCheckedAt)
        latestResult = try container.decodeIfPresent(VocabularyRating.self, forKey: .latestResult)
        sourceMaterialID = try container.decodeIfPresent(EntityID.self, forKey: .sourceMaterialID) ?? materialID
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
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
