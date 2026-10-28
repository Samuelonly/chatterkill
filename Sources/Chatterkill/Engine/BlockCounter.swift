//
//  BlockCounter.swift
//  Chatterkill
//
//  今日 / 累计拦截次数。只统计真正被吞掉的连击（chatter 且 blocked）。
//  跨天自动把今日清零，累计不清。无定时器：只在拦截发生时顺手算一下。
//

import Foundation

final class BlockCounter {

    private(set) var day: String
    private(set) var today: Int
    private(set) var total: Int

    /// 攒够这么多次才写一次盘，避免每次拦截都碰磁盘。
    private var unsaved = 0
    private static let saveEvery = 100

    init() {
        day = BlockCounter.todayKey()
        today = 0
        total = 0
    }

    func load(from stats: AppConfig.Stats) {
        let key = BlockCounter.todayKey()
        total = max(0, stats.blockedTotal)
        let savedDay = stats.day.isEmpty ? key : stats.day
        if savedDay == key {
            day = key
            today = max(0, stats.blockedToday)
        } else {
            // 上次记录是昨天的，今日从 0 起。
            day = key
            today = 0
        }
    }

    var snapshot: AppConfig.Stats {
        AppConfig.Stats(day: day, blockedToday: today, blockedTotal: total)
    }

    /// 记一次拦截。返回 true 表示需要写盘（跨天，或攒够 100 次）。
    func count() -> Bool {
        var needSave = false
        let key = BlockCounter.todayKey()
        if key != day {
            day = key
            today = 0
            needSave = true
        }

        today += 1
        total += 1
        unsaved += 1

        if unsaved >= BlockCounter.saveEvery {
            unsaved = 0
            needSave = true
        }
        return needSave
    }

    static func todayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
