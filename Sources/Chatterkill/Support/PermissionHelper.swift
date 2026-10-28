//
//  PermissionHelper.swift
//  Chatterkill
//
//  Accessibility permission only. Alpha never synthesizes key events, so
//  Input Monitoring is NOT required (that arrives with 1.0 "resent keystroke").
//  Forked from Debounce/PermissionHelper.swift (MIT, Timo Leisengang).
//

import Cocoa
import ApplicationServices

protocol AccessibilityPermissionChecking {
    func isAccessibilityTrusted(prompt: Bool) -> Bool
}

enum PermissionAlertAction: Equatable {
    case openSettings
    case repairPermission
    case cancel
}

enum PermissionHelperError: LocalizedError {
    case bundleIdentifierUnavailable
    case resetFailed(exitStatus: Int32)

    var errorDescription: String? {
        switch self {
        case .bundleIdentifierUnavailable:
            return Loc.t(
                "Chatterkill could not determine its bundle identifier, so Accessibility permission was not changed.",
                "Chatterkill 拿不到自己的 Bundle ID，未改动辅助功能授权。"
            )
        case .resetFailed(let exitStatus):
            return Loc.t(
                "Repairing the Accessibility permission failed (tccutil exit \(exitStatus)).",
                "修复辅助功能授权失败（tccutil 退出码 \(exitStatus)）。"
            )
        }
    }
}

final class PermissionHelper: AccessibilityPermissionChecking {

    private let bundleIdentifier: String?

    init(bundleIdentifier: String? = Bundle.main.bundleIdentifier) {
        self.bundleIdentifier = bundleIdentifier
    }

    func isAccessibilityTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// 弹窗三选一：去设置 / 修复失效条目 / 取消。返回用户实际选了哪个。
    @discardableResult
    func showPermissionAlert() throws -> PermissionAlertAction {
        let alert = NSAlert()
        alert.messageText = Loc.t("Accessibility Permission Required", "需要辅助功能授权")
        alert.informativeText = Loc.t(
            """
            Chatterkill needs Accessibility permission to intercept keyboard events.

            Choose “Open System Settings” to grant it. If Chatterkill already looks enabled there but still reports missing permission, choose “Repair Permission”: it removes only Chatterkill’s stale entry and asks macOS again.
            """,
            """
            Chatterkill 需要辅助功能授权，才能拦截键盘事件。

            选「打开系统设置」去勾选。如果那里看起来已经打开、软件却仍报缺权限，选「修复授权」：它只会删掉 Chatterkill 自己的失效条目并重新向系统申请。
            """
        )
        alert.alertStyle = .warning
        alert.addButton(withTitle: Loc.t("Open System Settings", "打开系统设置"))
        alert.addButton(withTitle: Loc.t("Repair Permission", "修复授权"))
        alert.addButton(withTitle: Loc.t("Cancel", "取消"))

        let action: PermissionAlertAction
        switch alert.runModal() {
        case .alertFirstButtonReturn: action = .openSettings
        case .alertSecondButtonReturn: action = .repairPermission
        default: action = .cancel
        }

        switch action {
        case .openSettings:
            requestNativePromptThenOpenSettings()
        case .repairPermission:
            try resetAccessibilityPermission()
            requestNativePromptThenOpenSettings()
        case .cancel:
            break
        }

        return action
    }

    /// 走系统原生授权的提示（非模态），并打开辅助功能面板。
    func requestAccessPrompt() {
        requestNativePromptThenOpenSettings()
    }

    func openAccessibilityPreferences() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private

    private func requestNativePromptThenOpenSettings() {
        _ = isAccessibilityTrusted(prompt: true)
        openAccessibilityPreferences()
    }

    private func resetAccessibilityPermission() throws {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
            throw PermissionHelperError.bundleIdentifierUnavailable
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", bundleIdentifier]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PermissionHelperError.resetFailed(exitStatus: process.terminationStatus)
        }
    }
}
