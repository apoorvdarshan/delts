import Combine
import Foundation

enum AppUpdateCheckResult: Equatable {
    case idle
    case checking
    case available(version: String, storeURL: URL?, releaseNotes: String?)
    case upToDate(latestVersion: String?, releaseNotes: String?)
    case unavailable
    case failed(message: String)
}

@MainActor
final class AppUpdateChecker: ObservableObject {
    @Published private(set) var isChecking = false
    @Published private(set) var isUpdateAvailable: Bool
    @Published private(set) var latestVersion: String?
    @Published private(set) var appStoreURL: URL?
    @Published private(set) var lastResult: AppUpdateCheckResult = .idle

    private static let updateAvailableKey = "delts.update.available"
    private static let latestVersionKey = "delts.update.latestVersion"
    private static let appStoreURLKey = "delts.update.appStoreURL"

    private let bundle: Bundle
    private let defaults: UserDefaults
    private let session: URLSession
    private var hasCheckedThisLaunch = false

    init(
        bundle: Bundle = .main,
        defaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        self.bundle = bundle
        self.defaults = defaults
        self.session = session

        let cachedVersion = defaults.string(forKey: Self.latestVersionKey)
        let cachedStoreURL = defaults.string(forKey: Self.appStoreURLKey).flatMap(URL.init(string:))
        self.latestVersion = cachedVersion
        self.appStoreURL = cachedStoreURL
        self.isUpdateAvailable = defaults.bool(forKey: Self.updateAvailableKey)
            && cachedVersion.map { Self.isVersion($0, newerThan: Self.currentVersion(in: bundle)) } == true
    }

    var currentVersion: String {
        Self.currentVersion(in: bundle)
    }

    func checkForUpdatesIfNeeded() async {
        guard !hasCheckedThisLaunch else { return }
        hasCheckedThisLaunch = true
        _ = await checkForUpdates()
    }

    @discardableResult
    func checkForUpdates() async -> AppUpdateCheckResult {
        guard !isChecking else { return lastResult }
        guard let bundleID = bundle.bundleIdentifier,
              let lookupURL = Self.lookupURL(bundleID: bundleID)
        else {
            let result = AppUpdateCheckResult.failed(message: "The app bundle identifier is unavailable.")
            lastResult = result
            return result
        }

        isChecking = true
        lastResult = .checking
        defer { isChecking = false }

        do {
            let (data, response) = try await session.data(from: lookupURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode)
            else {
                throw URLError(.badServerResponse)
            }

            let lookup = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
            guard let listing = lookup.results.first,
                  let appStoreVersion = listing.version?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !appStoreVersion.isEmpty
            else {
                clearCachedAvailability()
                let result = AppUpdateCheckResult.unavailable
                lastResult = result
                return result
            }

            let storeURL = listing.trackViewUrl.flatMap(URL.init(string:))
            let releaseNotes = listing.releaseNotes?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty
            latestVersion = appStoreVersion
            appStoreURL = storeURL
            defaults.set(appStoreVersion, forKey: Self.latestVersionKey)
            defaults.set(storeURL?.absoluteString, forKey: Self.appStoreURLKey)

            if Self.isVersion(appStoreVersion, newerThan: currentVersion) {
                isUpdateAvailable = true
                defaults.set(true, forKey: Self.updateAvailableKey)
                let result = AppUpdateCheckResult.available(version: appStoreVersion, storeURL: storeURL, releaseNotes: releaseNotes)
                lastResult = result
                return result
            }

            isUpdateAvailable = false
            defaults.set(false, forKey: Self.updateAvailableKey)
            let result = AppUpdateCheckResult.upToDate(latestVersion: appStoreVersion, releaseNotes: releaseNotes)
            lastResult = result
            return result
        } catch {
            let result = AppUpdateCheckResult.failed(message: "Could not check for updates. Try again later.")
            lastResult = result
            return result
        }
    }

    private func clearCachedAvailability() {
        isUpdateAvailable = false
        latestVersion = nil
        appStoreURL = nil
        defaults.set(false, forKey: Self.updateAvailableKey)
        defaults.removeObject(forKey: Self.latestVersionKey)
        defaults.removeObject(forKey: Self.appStoreURLKey)
    }

    private static func lookupURL(bundleID: String) -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: "us")
        ]
        return components?.url
    }

    private static func currentVersion(in bundle: Bundle) -> String {
        if let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.isEmpty {
            return version
        }

        if let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
           !build.isEmpty {
            return build
        }

        return "0"
    }

    private static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let candidateParts = versionParts(candidate)
        let currentParts = versionParts(current)
        let count = max(candidateParts.count, currentParts.count)

        for index in 0..<count {
            let candidateValue = index < candidateParts.count ? candidateParts[index] : 0
            let currentValue = index < currentParts.count ? currentParts[index] : 0

            if candidateValue > currentValue {
                return true
            }
            if candidateValue < currentValue {
                return false
            }
        }

        return false
    }

    private static func versionParts(_ version: String) -> [Int] {
        version
            .split { character in
                character == "." || character == "-" || character == "_"
            }
            .map { Int($0) ?? 0 }
    }
}

private struct AppStoreLookupResponse: Decodable {
    let results: [AppStoreLookupResult]
}

private struct AppStoreLookupResult: Decodable {
    let version: String?
    let trackViewUrl: String?
    let releaseNotes: String?
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
