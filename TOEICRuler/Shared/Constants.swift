import Foundation

enum TOEICPart: String, CaseIterable, Codable, Identifiable {
    case part1
    case part2
    case part3
    case part4
    case part5
    case part6
    case part7

    var id: String { rawValue }

    var number: Int {
        switch self {
        case .part1: 1
        case .part2: 2
        case .part3: 3
        case .part4: 4
        case .part5: 5
        case .part6: 6
        case .part7: 7
        }
    }

    var title: String { "Part \(number)" }

    var name: String {
        switch self {
        case .part1: "写真描写問題"
        case .part2: "応答問題"
        case .part3: "会話問題"
        case .part4: "説明文問題"
        case .part5: "短文穴埋め問題"
        case .part6: "長文穴埋め問題"
        case .part7: "読解問題"
        }
    }
}

enum MaterialType: String, CaseIterable, Codable, Identifiable {
    case officialBook
    case vocabularyBook
    case grammarBook
    case mockTest
    case app
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .officialBook: "公式問題集"
        case .vocabularyBook: "単語帳"
        case .grammarBook: "文法書"
        case .mockTest: "模試"
        case .app: "学習アプリ"
        case .other: "その他"
        }
    }
}

enum UnderstandingLevel: String, CaseIterable, Codable, Identifiable {
    case circle
    case triangle
    case cross

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .circle: "○"
        case .triangle: "△"
        case .cross: "×"
        }
    }

    var title: String {
        switch self {
        case .circle: "理解できた"
        case .triangle: "あいまい"
        case .cross: "未理解"
        }
    }
}

enum VocabularyRating: String, CaseIterable, Codable, Identifiable {
    case circle
    case triangle
    case cross

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .circle: "○"
        case .triangle: "△"
        case .cross: "×"
        }
    }

    var title: String {
        switch self {
        case .circle: "覚えた"
        case .triangle: "迷う"
        case .cross: "覚えていない"
        }
    }
}

enum FeatureTier: String, CaseIterable, Codable, Identifiable {
    case free
    case premium

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: "Free"
        case .premium: "Premium"
        }
    }
}

enum MistakeReasonCategory: String, CaseIterable, Codable, Identifiable {
    case vocabulary
    case grammar
    case listening
    case speed
    case careless
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vocabulary: "語彙不足"
        case .grammar: "文法理解"
        case .listening: "聞き取り"
        case .speed: "時間不足"
        case .careless: "ケアレスミス"
        case .other: "その他"
        }
    }
}
