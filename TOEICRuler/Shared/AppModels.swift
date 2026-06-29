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
    var studyLogID: EntityID?
    var part: TOEICPart?
    var text: String
    var manualTags: [String]
    var keywordTags: [String]
    var classificationType: MistakeClassificationType
    var category: MistakeReasonCategory
    var title: String
    var detail: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case studyLogID
        case part
        case text
        case manualTags
        case keywordTags
        case classificationType
        case category
        case title
        case detail
        case createdAt
        case updatedAt
    }

    init(
        id: EntityID,
        studyLogID: EntityID?,
        part: TOEICPart?,
        text: String,
        manualTags: [String],
        keywordTags: [String],
        classificationType: MistakeClassificationType,
        category: MistakeReasonCategory,
        title: String,
        detail: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.studyLogID = studyLogID
        self.part = part
        self.text = text
        self.manualTags = manualTags
        self.keywordTags = keywordTags
        self.classificationType = classificationType
        self.category = category
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(EntityID.self, forKey: .id)
        studyLogID = try container.decodeIfPresent(EntityID.self, forKey: .studyLogID)
        part = try container.decodeIfPresent(TOEICPart.self, forKey: .part)
        category = try container.decode(MistakeReasonCategory.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decodeIfPresent(String.self, forKey: .detail)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? detail ?? title
        manualTags = try container.decodeIfPresent([String].self, forKey: .manualTags) ?? []
        keywordTags = try container.decodeIfPresent([String].self, forKey: .keywordTags) ?? []
        classificationType = try container.decodeIfPresent(MistakeClassificationType.self, forKey: .classificationType) ?? .keyword
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
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
