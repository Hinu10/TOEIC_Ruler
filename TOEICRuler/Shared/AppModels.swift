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
    var part: TOEICPart
    var manualNoteText: String
    var mistakeReasonText: String
    var manualTags: [String]
    var keywordTags: [String]
    var studyLogID: EntityID?
    var materialID: EntityID?
    var studyDate: Date?
    var relatedStudyLogIDs: [EntityID]
    var aiGeneratedNoteText: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case part
        case manualNoteText
        case mistakeReasonText
        case manualTags
        case keywordTags
        case studyLogID
        case materialID
        case studyDate
        case relatedStudyLogIDs
        case aiGeneratedNoteText
        case createdAt
        case updatedAt
        case legacyTitle = "title"
        case legacyMistakeReasonID = "mistakeReasonID"
        case legacyBody = "body"
    }

    init(
        id: EntityID,
        part: TOEICPart,
        manualNoteText: String,
        mistakeReasonText: String,
        manualTags: [String],
        keywordTags: [String],
        studyLogID: EntityID?,
        materialID: EntityID?,
        studyDate: Date?,
        relatedStudyLogIDs: [EntityID],
        aiGeneratedNoteText: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.part = part
        self.manualNoteText = manualNoteText
        self.mistakeReasonText = mistakeReasonText
        self.manualTags = manualTags
        self.keywordTags = keywordTags
        self.studyLogID = studyLogID
        self.materialID = materialID
        self.studyDate = studyDate
        self.relatedStudyLogIDs = relatedStudyLogIDs
        self.aiGeneratedNoteText = aiGeneratedNoteText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(EntityID.self, forKey: .id)
        let part = try container.decode(TOEICPart.self, forKey: .part)
        let manualNoteText = try container.decodeIfPresent(String.self, forKey: .manualNoteText)
            ?? container.decodeIfPresent(String.self, forKey: .legacyBody)
            ?? ""
        let mistakeReasonText = try container.decodeIfPresent(String.self, forKey: .mistakeReasonText) ?? ""
        let manualTags = try container.decodeIfPresent([String].self, forKey: .manualTags) ?? []
        let keywordTags = try container.decodeIfPresent([String].self, forKey: .keywordTags) ?? []
        let studyLogID = try container.decodeIfPresent(EntityID.self, forKey: .studyLogID)
        let materialID = try container.decodeIfPresent(EntityID.self, forKey: .materialID)
        let studyDate = try container.decodeIfPresent(Date.self, forKey: .studyDate)
        let relatedStudyLogIDs = try container.decodeIfPresent([EntityID].self, forKey: .relatedStudyLogIDs) ?? []
        let aiGeneratedNoteText = try container.decodeIfPresent(String.self, forKey: .aiGeneratedNoteText)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        self.init(
            id: id,
            part: part,
            manualNoteText: manualNoteText,
            mistakeReasonText: mistakeReasonText,
            manualTags: manualTags,
            keywordTags: keywordTags,
            studyLogID: studyLogID,
            materialID: materialID,
            studyDate: studyDate,
            relatedStudyLogIDs: relatedStudyLogIDs,
            aiGeneratedNoteText: aiGeneratedNoteText,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(part, forKey: .part)
        try container.encode(manualNoteText, forKey: .manualNoteText)
        try container.encode(mistakeReasonText, forKey: .mistakeReasonText)
        try container.encode(manualTags, forKey: .manualTags)
        try container.encode(keywordTags, forKey: .keywordTags)
        try container.encodeIfPresent(studyLogID, forKey: .studyLogID)
        try container.encodeIfPresent(materialID, forKey: .materialID)
        try container.encodeIfPresent(studyDate, forKey: .studyDate)
        try container.encode(relatedStudyLogIDs, forKey: .relatedStudyLogIDs)
        try container.encodeIfPresent(aiGeneratedNoteText, forKey: .aiGeneratedNoteText)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
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
