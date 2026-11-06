//
//  ChatterBlocker.swift
//  Chatterkill
//
//  Core chatter detection. Runs synchronously on the main run loop inside the
//  event-tap callback: no timers, no polling, no background threads.
//  When no key is pressed the process is completely idle.
//  Forked from Debounce/ChatterBlocker.swift (MIT, Timo Leisengang).
//

import Foundation
import CoreGraphics
import Carbon.HIToolbox

enum KeyVerdict: String {
    /// 绿灯：间隔 ≥ 阈值，正常
    case normal
    /// 红灯：间隔 < 阈值，冒字
    case chatter
    /// 蓝灯：按住过久，疑似迟钝 / 丢了抬起事件
    case slow
}

enum KeyPhase: String {
    case down
    case up
}

struct KeyEvent {
    let keyCode: CGKeyCode
    let name: String
    let phase: KeyPhase
    /// 距上一次同类事件的毫秒数；首次按下为 0
    let intervalMs: UInt64
    /// 本次按住时长（仅 keyUp 有意义）
    let heldMs: UInt64
    let thresholdMs: UInt64
    let verdict: KeyVerdict
    let blocked: Bool
}

final class ChatterBlocker {

    // MARK: - Configuration

    var isEnabled = true
    var globalThresholdMs: UInt64 = 100
    /// 比这个还短的间隔直接忽略（脏硬件专用），0 = 关闭
    var minimumChatterMs: UInt64 = 0
    /// 菜单「拦截功能键」：false 时修饰键 / Fn / F1–F15 任何情况下都不吞。
    var blockFunctionKeys = false
    /// 菜单「拦截密码框」：false 时系统停用 tap（Secure Input）后不再强行重开。
    var blockPasswordFields = true

    /// 54–63 = 左右 Shift / Command / Option / Control + Caps Lock + Fn。
    static let functionKeyCodes: Set<CGKeyCode> = Set(
        (54...63).map { CGKeyCode($0) } + [
            CGKeyCode(kVK_F1), CGKeyCode(kVK_F2), CGKeyCode(kVK_F3), CGKeyCode(kVK_F4),
            CGKeyCode(kVK_F5), CGKeyCode(kVK_F6), CGKeyCode(kVK_F7), CGKeyCode(kVK_F8),
            CGKeyCode(kVK_F9), CGKeyCode(kVK_F10), CGKeyCode(kVK_F11), CGKeyCode(kVK_F12),
            CGKeyCode(kVK_F13), CGKeyCode(kVK_F14), CGKeyCode(kVK_F15)
        ]
    )

    private(set) var perKeyThresholdMs: [CGKeyCode: UInt64] = [:]

    /// 按住超过这个时长再抬起 → 蓝灯（启发式，α 版先给 1200ms）
    var slowHoldMs: UInt64 = 1_200

    // MARK: - Output

    /// 每个非重复按键事件都会回调一次，面板活着时由 UI 层转发。
    var onKeyEvent: ((KeyEvent) -> Void)?

    // MARK: - State

    private var lastPressAt: [CGKeyCode: UInt64] = [:]
    private var lastReleaseAt: [CGKeyCode: UInt64] = [:]
    private var isDown: [CGKeyCode: Bool] = [:]
    private var downAt: [CGKeyCode: UInt64] = [:]
    private var downWasBlocked: [CGKeyCode: Bool] = [:]
    private let now: () -> UInt64

    init(now: @escaping () -> UInt64 = { UInt64(ProcessInfo.processInfo.systemUptime * 1_000) }) {
        self.now = now
    }

    // MARK: - Thresholds

    func threshold(for keyCode: CGKeyCode) -> UInt64 {
        perKeyThresholdMs[keyCode] ?? globalThresholdMs
    }

    func setThreshold(_ milliseconds: UInt64?, for keyCode: CGKeyCode) {
        if let milliseconds {
            perKeyThresholdMs[keyCode] = milliseconds
        } else {
            perKeyThresholdMs.removeValue(forKey: keyCode)
        }
    }

    // MARK: - Event handling

    /// 返回 true = 放行，false = 吞掉这次按下。
    @discardableResult
    func handleKeyDown(keyCode: CGKeyCode) -> Bool {
        // 未勾选「拦截功能键」时，功能键直接放行，不进任何计时状态。
        if !blockFunctionKeys, Self.functionKeyCodes.contains(keyCode) {
            return true
        }

        // 按住重复（auto-repeat）不算新按键，原样放行，也不上报面板。
        if isDown[keyCode] == true {
            return true
        }

        let timeNow = now()
        isDown[keyCode] = true
        downAt[keyCode] = timeNow

        let threshold = threshold(for: keyCode)
        var interval: UInt64 = 0
        var isChatter = false

        if let last = lastPressAt[keyCode] {
            interval = timeNow >= last ? timeNow - last : 0
            isChatter = threshold > 0
                && interval >= minimumChatterMs
                && interval < threshold
        }

        lastPressAt[keyCode] = timeNow

        let blocked = isChatter && isEnabled
        if blocked {
            downWasBlocked[keyCode] = true
        }

        report(keyCode: keyCode,
               phase: .down,
               interval: interval,
               held: 0,
               threshold: threshold,
               verdict: isChatter ? .chatter : .normal,
               blocked: blocked)

        return !blocked
    }

    /// 返回 true = 放行，false = 吞掉这次抬起（按下被吞时必须一起吞）。
    @discardableResult
    func handleKeyUp(keyCode: CGKeyCode) -> Bool {
        if !blockFunctionKeys, Self.functionKeyCodes.contains(keyCode) {
            return true
        }

        let timeNow = now()
        lastReleaseAt[keyCode] = timeNow

        var held: UInt64 = 0
        if let began = downAt[keyCode], timeNow >= began {
            held = timeNow - began
        }

        isDown[keyCode] = false
        downAt[keyCode] = nil

        var blocked = false
        if isEnabled, downWasBlocked[keyCode] == true {
            downWasBlocked[keyCode] = false
            blocked = true
        }

        report(keyCode: keyCode,
               phase: .up,
               interval: 0,
               held: held,
               threshold: threshold(for: keyCode),
               verdict: held >= slowHoldMs ? .slow : .normal,
               blocked: blocked)

        return !blocked
    }

    /// 暂停 / 恢复时清干净计时状态，避免误判。
    func resetTimingData() {
        lastPressAt.removeAll()
        lastReleaseAt.removeAll()
        isDown.removeAll()
        downAt.removeAll()
        downWasBlocked.removeAll()
    }

    private func report(
        keyCode: CGKeyCode,
        phase: KeyPhase,
        interval: UInt64,
        held: UInt64,
        threshold: UInt64,
        verdict: KeyVerdict,
        blocked: Bool
    ) {
        guard let onKeyEvent else { return }
        onKeyEvent(KeyEvent(
            keyCode: keyCode,
            name: KeyMap.name(for: keyCode),
            phase: phase,
            intervalMs: interval,
            heldMs: held,
            thresholdMs: threshold,
            verdict: verdict,
            blocked: blocked
        ))
    }
}
