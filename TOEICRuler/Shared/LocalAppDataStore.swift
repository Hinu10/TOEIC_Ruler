import Foundation

struct StoragePolicy {
    let kind: String
    let key: String
    let description: String
}

final class LocalAppDataStore {
    static let shared = LocalAppDataStore()

    static let policy = StoragePolicy(
        kind: "UserDefaults",
        key: "toeic-ruler.mvp-data.v1",
        description: "MVPでは認証と外部DBを使わず、端末内のUserDefaultsに学習データをJSON保存する。"
    )

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> AppData {
        guard let data = defaults.data(forKey: Self.policy.key) else {
            return .empty
        }

        do {
            return try decoder.decode(AppData.self, from: data)
        } catch {
            return .empty
        }
    }

    func save(_ appData: AppData) throws {
        let data = try encoder.encode(appData)
        defaults.set(data, forKey: Self.policy.key)
    }

    func clear() {
        defaults.removeObject(forKey: Self.policy.key)
    }
}
