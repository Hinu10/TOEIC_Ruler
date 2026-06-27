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
    var studyRange: String
    var part: TOEICPart
    var round: Int
    var minutes: Int
    var questionCount: Int?
    var correctCount: Int?
    var understanding: UnderstandingLevel
    var mistakeReasonIDs: [EntityID]
    var mistakeReasonText: String?
    var memo: String?
    var createdAt: Date
    var updatedAt: Date

    var accuracyRate: Double? {
        guard
            let questionCount,
            let correctCount,
            questionCount > 0
        else {
            return nil
        }
        return Double(correctCount) / Double(questionCount)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case studiedOn
        case materialID
        case studyRange
        case part
        case round
        case minutes
        case questionCount
        case correctCount
        case understanding
        case mistakeReasonIDs
        case mistakeReasonText
        case memo
        case createdAt
        case updatedAt
    }

    init(
        id: EntityID,
        studiedOn: Date,
        materialID: EntityID?,
        studyRange: String,
        part: TOEICPart,
        round: Int,
        minutes: Int,
        questionCount: Int?,
        correctCount: Int?,
        understanding: UnderstandingLevel,
        mistakeReasonIDs: [EntityID] = [],
        mistakeReasonText: String?,
        memo: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.studiedOn = studiedOn
        self.materialID = materialID
        self.studyRange = studyRange
        self.part = part
        self.round = round
        self.minutes = minutes
        self.questionCount = questionCount
        self.correctCount = correctCount
        self.understanding = understanding
        self.mistakeReasonIDs = mistakeReasonIDs
        self.mistakeReasonText = mistakeReasonText
        self.memo = memo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(EntityID.self, forKey: .id)
        studiedOn = try container.decode(Date.self, forKey: .studiedOn)
        materialID = try container.decodeIfPresent(EntityID.self, forKey: .materialID)
        studyRange = try container.decodeIfPresent(String.self, forKey: .studyRange) ?? ""
        part = try container.decode(TOEICPart.self, forKey: .part)
        round = try container.decodeIfPresent(Int.self, forKey: .round) ?? 1
        minutes = try container.decode(Int.self, forKey: .minutes)
        questionCount = try container.decodeIfPresent(Int.self, forKey: .questionCount)
        correctCount = try container.decodeIfPresent(Int.self, forKey: .correctCount)
        understanding = try container.decode(UnderstandingLevel.self, forKey: .understanding)
        mistakeReasonIDs = try container.decodeIfPresent([EntityID].self, forKey: .mistakeReasonIDs) ?? []
        mistakeReasonText = try container.decodeIfPresent(String.self, forKey: .mistakeReasonText)
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
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
