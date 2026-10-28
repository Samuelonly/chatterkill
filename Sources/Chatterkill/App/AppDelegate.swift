//
//  AppDelegate.swift
//  Chatterkill
//
//  Menu-bar only (LSUIElement). Owns the engine, config, and the debug panel.
//  The engine is event-driven: no timers, no polling (PRD 3.1 R2).
//

import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    // MARK: - Engine

    let blocker = ChatterBlocker()
    let store = ConfigStore()
    private let typing = TypingCounter()
    private let permissionHelper = PermissionHelper()
    private var interceptor: EventInterceptor?

    // MARK: - UI

    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?
    private var toggleMenuItem: NSMenuItem?
    private var todayMenuItem: NSMenuItem?
    private var totalMenuItem: NSMenuItem?
    private var launchAtLoginMenuItem: NSMenuItem?

    private let panel = PanelController()

    /// 引擎是否已在跑。避免每次 App 激活都把 tap 拆了重建（R2）。
    private var engineRunning = false

    private var isEnabled: Bool {
        get { blocker.isEnabled }
        set { blocker.isEnabled = newValue }
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        store.blockerProvider = { [weak self] in self?.blocker }
        store.apply(to: blocker)
        typing.load(from: store.config.stats)

        setupMenuBar()

        let interceptor = EventInterceptor(chatterBlocker: blocker)
        interceptor.onTapDied = { [weak self] in self?.handleTapDied() }
        self.interceptor = interceptor

        // 面板只在活着时收事件；关掉后 send() 直接 return，零开销（R1）。
        blocker.onKeyEvent = { [weak self] event in
            guard let self else { return }
            // 每次按下顺手记一个字；被吞掉的连击不算（没出字）。
            if event.phase == .down, !event.blocked, self.typing.count(event.name) {
                self.store.config.stats = self.typing.snapshot
                self.store.write()
            }
            self.panel.send(event)
        }

        panel.statusProvider = { [weak self] in
            guard let self else { return (false, false) }
            return (self.permissionHelper.isAccessibilityTrusted(prompt: false), self.blocker.isEnabled)
        }

        panel.onOpenPermission = { [weak self] in
            guard let self else { return }
            _ = try? self.permissionHelper.showPermissionAlert()
            self.refreshMenu()
            self.panel.refreshStatus(self.store.config)
        }

        panel.onSetThreshold = { [weak self] name, milliseconds in
            guard let self else { return }
            if let code = KeyMap.code(for: name) {
                self.blocker.setThreshold(milliseconds, for: code)
            }
            if let milliseconds {
                self.store.config.perKey[name] = Int(milliseconds)
            } else {
                self.store.config.perKey.removeValue(forKey: name)
            }
            self.store.write()
        }

        if isEnabled {
            startEngine(presentPermissionAlert: true)
        } else {
            refreshMenu()
        }

        syncLaunchAtLogin()

        // 首次运行（还没走完引导）直接弹一次面板，否则用户双击后什么都看不见。
        if !store.config.hasCompletedOnboarding {
            store.config.hasCompletedOnboarding = true
            panel.present(config: store.config)
        }

        store.write()
    }

    func applicationWillTerminate(_ notification: Notification) {
        interceptor?.stop()
        blocker.resetTimingData()
        store.capture(from: blocker)
        store.config.stats = typing.snapshot
        store.write()
    }

    /// 双击 app（或 Dock 里点开）时给一个可见反馈。
    /// LSUIElement 的 app 没有窗口，双击只“激活”一个看不见的进程，用户会以为打不开。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            panel.present(config: store.config)
        }
        return true
    }

    /// 从系统设置回来时重试（用户刚勾上辅助功能）。已经在跑就不动 tap。
    func applicationDidBecomeActive(_ notification: Notification) {
        guard isEnabled, !engineRunning,
              permissionHelper.isAccessibilityTrusted(prompt: false) else { return }
        startEngine(presentPermissionAlert: false)
        panel.refreshStatus(store.config)
    }

    // MARK: - Engine control

    private func startEngine(presentPermissionAlert: Bool) {
        guard let interceptor else { return }

        let trusted = permissionHelper.isAccessibilityTrusted(prompt: false)
        let result = interceptor.start()
        NSLog("Chatterkill: engine start → \(result), accessibilityTrusted=\(trusted)")

        switch result {
        case .started:
            engineRunning = true
        case .accessibilityPermissionRequired:
            if presentPermissionAlert {
                // 用系统原生提示，不弹自定义模态框：启动时不打断用户。
                permissionHelper.requestAccessPrompt()
            }
        case .eventTapCreationFailed:
            engineRunning = false
            presentAlert(
                Loc.t("Keyboard Monitor Could Not Start",
                      "键盘监听没能启动"),
                Loc.t("Accessibility permission is granted, but macOS refused to create the event tap. Toggle Chatterkill off and on again.",
                      "辅助功能已授权，但系统拒绝创建事件监听。把 Chatterkill 关一次再开。")
            )
        case .runLoopSourceCreationFailed:
            presentAlert(
                Loc.t("Keyboard Monitor Could Not Attach",
                      "键盘监听没能挂上"),
                Loc.t("The event tap was created but could not attach to the app run loop. Quit and reopen Chatterkill.",
                      "事件监听创建成功但挂不到 App 主循环。退出后重新打开 Chatterkill。")
            )
        }

        refreshMenu()
    }

    private func handleTapDied() {
        interceptor?.stop()
        engineRunning = false
        presentAlert(
            Loc.t("Chatter blocking stopped", "拦键已停止"),
            Loc.t("The keyboard event monitor was terminated by the system. Turn Chatterkill off and on again from the menu bar.",
                  "系统把键盘事件监听停掉了。请从菜单栏把 Chatterkill 关一次再开。")
        )
        refreshMenu()
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "keyboard",
                accessibilityDescription: "Chatterkill"
            )
            button.image?.isTemplate = true
        }

        let menu = NSMenu()

        let status = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        status.isEnabled = false
        statusMenuItem = status
        menu.addItem(status)

        menu.addItem(.separator())

        // 打字统计两栏：今日 / 累计。打开菜单时刷新，不做定时器。
        let today = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        today.isEnabled = false
        todayMenuItem = today
        menu.addItem(today)

        let total = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        total.isEnabled = false
        totalMenuItem = total
        menu.addItem(total)

        menu.addItem(.separator())

        let toggle = NSMenuItem(
            title: "",
            action: #selector(toggleBlocking),
            keyEquivalent: ""
        )
        toggle.target = self
        toggleMenuItem = toggle
        menu.addItem(toggle)

        let openPanel = NSMenuItem(
            title: Loc.t("Open Tester…", "打开检测面板…"),
            action: #selector(openPanel),
            keyEquivalent: ""
        )
        openPanel.target = self
        menu.addItem(openPanel)

        menu.addItem(.separator())

        let launch = NSMenuItem(
            title: Loc.t("Launch at Login", "开机自启"),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launch.target = self
        launchAtLoginMenuItem = launch
        menu.addItem(launch)

        let repair = NSMenuItem(
            title: Loc.t("Accessibility Permission…", "辅助功能授权…"),
            action: #selector(openPermissionSettings),
            keyEquivalent: ""
        )
        repair.target = self
        menu.addItem(repair)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: Loc.t("Quit Chatterkill", "退出 Chatterkill"),
            action: #selector(quit),
            keyEquivalent: ""
        )
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        menu.delegate = self
        refreshMenu()
    }

    private func refreshMenu() {
        let trusted = permissionHelper.isAccessibilityTrusted(prompt: false)

        let statusText: String
        if !trusted {
            statusText = Loc.t("Permission missing — not blocking", "缺授权 · 未拦截")
        } else if isEnabled {
            statusText = Loc.t("Blocking · listening", "拦截中 · 监听中")
        } else {
            statusText = Loc.t("Paused", "已暂停")
        }

        statusMenuItem?.attributedTitle = NSAttributedString(
            string: statusText,
            attributes: [
                .foregroundColor: !trusted ? NSColor.systemYellow : (isEnabled ? NSColor.systemGreen : NSColor.secondaryLabelColor),
                .font: NSFont.menuFont(ofSize: 0)
            ]
        )

        toggleMenuItem?.title = isEnabled
            ? Loc.t("Pause Blocking", "暂停拦截")
            : Loc.t("Start Blocking", "开始拦截")

        launchAtLoginMenuItem?.state = launchAtLoginEnabled ? .on : .off

        updateTypingMenuItems()

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: trusted ? "keyboard" : "keyboard.badge.exclamationmark",
                accessibilityDescription: "Chatterkill"
            )
            button.image?.isTemplate = true
            button.contentTintColor = !trusted
                ? .systemYellow
                : (isEnabled ? nil : .secondaryLabelColor)
            button.appearsDisabled = trusted && !isEnabled
        }
    }

    // MARK: - Menu delegate

    func menuWillOpen(_ menu: NSMenu) {
        updateTypingMenuItems()
    }

    private func updateTypingMenuItems() {
        todayMenuItem?.attributedTitle = typingMenuTitle(
            Loc.t("Today", "今日字数"), value: typing.today
        )
        totalMenuItem?.attributedTitle = typingMenuTitle(
            Loc.t("Total", "累计字数"), value: typing.total
        )
    }

    /// 禁用态菜单项默认会被画成灰色；这里显式指定颜色，深色模式下也看得清。
    private func typingMenuTitle(_ title: String, value: Int) -> NSAttributedString {
        let label = NSFont.menuFont(ofSize: 0)
        let numberFont = NSFont.monospacedDigitSystemFont(ofSize: label.pointSize, weight: .regular)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"

        let result = NSMutableAttributedString(
            string: title + "  ",
            attributes: [.foregroundColor: NSColor.labelColor, .font: label]
        )
        result.append(NSAttributedString(
            string: number,
            attributes: [.foregroundColor: NSColor.labelColor, .font: numberFont]
        ))
        return result
    }

    // MARK: - Actions

    @objc private func toggleBlocking() {
        blocker.isEnabled.toggle()
        store.capture(from: blocker)
        store.write()

        if blocker.isEnabled {
            startEngine(presentPermissionAlert: true)
        } else {
            interceptor?.stop()
            engineRunning = false
            blocker.resetTimingData()
            refreshMenu()
        }
    }

    @objc private func openPanel() {
        panel.present(config: store.config)
    }

    @objc private func openPermissionSettings() {
        _ = try? permissionHelper.showPermissionAlert()
        refreshMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        let enable = !launchAtLoginEnabled
        do {
            try setLaunchAtLogin(enable)
        } catch {
            presentAlert(
                Loc.t("Launch at Login", "开机自启"),
                Loc.t(
                    "macOS needs your approval: System Settings → General → Login Items.",
                    "需要你在「系统设置 → 通用 → 登录项」里允许 Chatterkill。"
                )
            )
            SMAppService.openSystemSettingsLoginItems()
        }
        store.config.launchAtLogin = launchAtLoginEnabled
        store.write()
        refreshMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Launch at login (PRD 3.1 R3)

    private var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status == .enabled else { return }
            try SMAppService.mainApp.unregister()
        }
    }

    /// 每次启动对齐一次自启状态：配置里要自启、装在 /Applications、系统里却没注册 → 补注册。
    /// 这样用户把 app 从别处挪进 /Applications 也能自愈（R3）。
    private func syncLaunchAtLogin() {
        guard store.config.launchAtLogin,
              Bundle.main.bundlePath.hasPrefix("/Applications") else { return }
        guard SMAppService.mainApp.status != .enabled else { return }

        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("Chatterkill: launch-at-login register failed — \(error.localizedDescription)")
        }
        NSLog("Chatterkill: launch-at-login status = \(SMAppService.mainApp.status.rawValue)")
        refreshMenu()
    }

    // MARK: - Alerts

    private func presentAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
