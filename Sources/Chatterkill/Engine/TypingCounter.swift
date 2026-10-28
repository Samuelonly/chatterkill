//
//  TypingCounter.swift
//  Chatterkill
//
//  今日 / 累计字数。只统计“会出字”的键，导航键、功能键、删除键都不算。
//  跨天自动把今日清零，累计不清。无定时器：只在按键时顺手算一下。
//

import Foundation

final class TypingCounter {

    private(set) var day: String
    private(set) var today: Int
    private(set) var total: Int

    /// 攒够这么多字才写一次盘，避免每次按键都碰磁盘。
    private var unsaved = 0
    private static let saveEvery = 100

    /// 不出字的键：导航、功能键、删除、Esc、Tab、音量等。
    private static let nonTyping: Set<String> = [
        "Escape", "Tab", "Delete", "ForwardDelete", "Help",
        "LeftArrow", "RightArrow", "UpArrow", "DownArrow",
        "Home", "End", "PageUp", "PageDown",
        "CapsLock", "Function", "Fn1", "Fn2",
        "VolumeUp", "VolumeDown", "Mute",
        "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8",
        "F9", "F10", "F11", "F12", "F13", "F14", "F15",
        "KeypadClear"
    ]

    init() {
        day = TypingCounter.todayKey()
        today = 0
        total = 0
    }

    func load(from stats: AppConfig.Stats) {
        let key = TypingCounter.todayKey()
        total = max(0, stats.total)
        let savedDay = stats.day.isEmpty ? key : stats.day
        if savedDay == key {
            day = key
            today = max(0, stats.today)
        } else {
            // 上次记录是昨天的，今日从 0 起。
            day = key
            today = 0
        }
    }

    var snapshot: AppConfig.Stats {
        AppConfig.Stats(day: day, today: today, total: total)
    }

    /// 记一个字。返回 true 表示需要写盘（跨天，或攒够 100 字）。
    func count(_ name: String) -> Bool {
        guard !TypingCounter.nonTyping.contains(name) else { return false }

        var needSave = false
        let key = TypingCounter.todayKey()
        if key != day {
            day = key
            today = 0
            needSave = true
        }

        today += 1
        total += 1
        unsaved += 1

        if unsaved >= TypingCounter.saveEvery {
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
