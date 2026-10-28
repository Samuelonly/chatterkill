//
//  ConfigStore.swift
//  Chatterkill
//
//  Plain-text JSON at ~/Library/Application Support/Chatterkill/config.json
//  (PRD 4.3). Readable/editable by hand so forks can tweak thresholds.
//  Upstream Debounce used UserDefaults; we do not back-fill from it.
//

import Foundation
import CoreGraphics

struct AppConfig: Codable, Equatable {

    struct Global: Codable, Equatable {
        var enabled: Bool = true
        var thresholdMs: Int = 100
    }

    struct UI: Codable, Equatable {
        var showAnomalyDot: Bool = false
    }

    /// 打字统计：今日 / 累计字数。
    struct Stats: Codable, Equatable {
        var day: String = ""
        var today: Int = 0
        var total: Int = 0

        init(day: String = "", today: Int = 0, total: Int = 0) {
            self.day = day
            self.today = today
            self.total = total
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            day = (try container.decodeIfPresent(String.self, forKey: .day)) ?? ""
            today = (try container.decodeIfPresent(Int.self, forKey: .today)) ?? 0
            total = (try container.decodeIfPresent(Int.self, forKey: .total)) ?? 0
        }
    }

    var global: Global = Global()
    /// 键名 -> 阈值毫秒。键名用 KeyMap 里的名字（"W"、"F1"、"Keypad0"），可读、可手改。
    var perKey: [String: Int] = [:]
    var locked: [String] = ["Fn1", "Fn2"]
    var ui: UI = UI()
    var stats: Stats = Stats()
    var launchAtLogin: Bool = true
    /// 是否已完成首次引导（用于 R3：首次即默认注册自启）
    var hasCompletedOnboarding: Bool = false

    // 手写解码：老版本配置缺字段时静默回落默认值，不整份丢弃。
    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = AppConfig()

        if let global = try container.decodeIfPresent(Global.self, forKey: .global) {
            self.global = global
        } else {
            self.global = fallback.global
        }
        perKey = (try container.decodeIfPresent([String: Int].self, forKey: .perKey)) ?? fallback.perKey
        locked = (try container.decodeIfPresent([String].self, forKey: .locked)) ?? fallback.locked
        if let ui = try container.decodeIfPresent(UI.self, forKey: .ui) {
            self.ui = ui
        } else {
            self.ui = fallback.ui
        }
        if let stats = try container.decodeIfPresent(Stats.self, forKey: .stats) {
            self.stats = stats
        } else {
            self.stats = fallback.stats
        }
        launchAtLogin = (try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin)) ?? fallback.launchAtLogin
        hasCompletedOnboarding = (try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding))
            ?? fallback.hasCompletedOnboarding
    }
}

final class ConfigStore {

    static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Chatterkill", isDirectory: true)
    }

    static var fileURL: URL {
        supportDirectory.appendingPathComponent("config.json")
    }

    var config: AppConfig

    init() {
        config = ConfigStore.read() ?? AppConfig()
    }

    // MARK: - Engine sync

    func apply(to blocker: ChatterBlocker) {
        blocker.isEnabled = config.global.enabled
        blocker.globalThresholdMs = UInt64(max(0, config.global.thresholdMs))
        for (name, milliseconds) in config.perKey {
            guard let code = KeyMap.code(for: name) else { continue }
            blocker.setThreshold(UInt64(max(0, milliseconds)), for: code)
        }
    }

    func capture(from blocker: ChatterBlocker) {
        config.global.enabled = blocker.isEnabled
        config.global.thresholdMs = Int(blocker.globalThresholdMs)
        var perKey: [String: Int] = [:]
        for (code, milliseconds) in blocker.perKeyThresholdMs {
            perKey[KeyMap.name(for: code)] = Int(milliseconds)
        }
        config.perKey = perKey
    }

    // MARK: - Disk

    func save() {
        captureBlockerIfNeeded()
        write()
    }

    func write() {
        do {
            try FileManager.default.createDirectory(
                at: ConfigStore.supportDirectory,
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: ConfigStore.fileURL, options: .atomic)
        } catch {
            NSLog("Chatterkill: failed to write config.json — \(error)")
        }
    }

    /// 由 AppDelegate 注入，避免 save() 时找不到 blocker 引用。
    var blockerProvider: (() -> ChatterBlocker?)?

    private func captureBlockerIfNeeded() {
        guard let blocker = blockerProvider?() else { return }
        capture(from: blocker)
    }

    // MARK: - Helpers

    static func read() -> AppConfig? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            NSLog("Chatterkill: config.json is invalid, using defaults — \(error)")
            return nil
        }
    }
}
