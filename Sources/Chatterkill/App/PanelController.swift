//
//  PanelController.swift
//  Chatterkill
//
//  The tester panel is a one-shot settings wizard (PRD 3.1 R1).
//  Closing it must leave nothing behind: no web process, no handlers, no timers.
//

import AppKit
import WebKit

final class PanelController: NSObject, NSWindowDelegate, WKScriptMessageHandler, WKNavigationDelegate {

    private var window: NSWindow?
    private var webView: WKWebView?

    var onSetThreshold: ((String, UInt64?) -> Void)?
    var onFinish: (() -> Void)?
    var onOpenPermission: (() -> Void)?

    /// 面板顶部状态灯只信真实状态：缺授权时不能假装“监听中”。
    var statusProvider: (() -> (trusted: Bool, enabled: Bool))?

    var isOpen: Bool { webView != nil }

    private var pendingConfig: AppConfig?

    // MARK: - Present / close

    func present(config: AppConfig) {
        pendingConfig = config

        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            pushConfig(config)
            return
        }

        let controller = WKUserContentController()
        controller.add(self, name: "chatterkill")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.websiteDataStore = .nonPersistent()

        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 1040, height: 620), configuration: configuration)
        web.autoresizingMask = [.width, .height]
        web.allowsBackForwardNavigationGestures = false
        web.navigationDelegate = self
        web.underPageBackgroundColor = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.12, alpha: 1)

        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Chatterkill"
        panel.backgroundColor = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        panel.isReleasedWhenClosed = false
        panel.contentView = web
        panel.delegate = self
        panel.minSize = NSSize(width: 900, height: 560)
        panel.center()

        webView = web
        window = panel

        guard let html = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web"),
              let webRoot = Bundle.main.resourceURL?.appendingPathComponent("web") else {
            NSLog("Chatterkill: web/index.html missing from bundle")
            close()
            return
        }

        web.loadFileURL(html, allowingReadAccessTo: webRoot)

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 彻底销毁：停加载、去 handler、摘视图、置 nil。少一步 R1 就不达标。
    func close() {
        webView?.stopLoading()
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "chatterkill")
        webView?.configuration.userContentController.removeAllUserScripts()
        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil

        window?.delegate = nil
        window?.contentView = nil
        window?.close()
        window = nil

        pendingConfig = nil
    }

    func windowWillClose(_ notification: Notification) {
        close()
        onFinish?()
    }

    // MARK: - Event feed

    func send(_ event: KeyEvent) {
        guard webView != nil else { return }
        let payload: [String: Any] = [
            "name": event.name,
            "phase": event.phase.rawValue,
            "intervalMs": Int(event.intervalMs),
            "heldMs": Int(event.heldMs),
            "thresholdMs": Int(event.thresholdMs),
            "verdict": event.verdict.rawValue,
            "blocked": event.blocked
        ]
        guard let json = PanelController.encode(payload) else { return }
        evaluate("window.Chatterkill && window.Chatterkill.key(\(json));")
    }

    /// 授权状态变了（比如用户刚在系统设置里勾上）刷新顶部状态灯。
    func refreshStatus(_ config: AppConfig) {
        guard webView != nil else { return }
        pushConfig(config)
    }

    private func pushConfig(_ config: AppConfig) {
        var payload: [String: Any] = [
            "global": ["thresholdMs": config.global.thresholdMs, "enabled": config.global.enabled],
            "perKey": config.perKey,
            "locked": config.locked
        ]
        if let status = statusProvider?() {
            payload["trusted"] = status.trusted
            payload["enabled"] = status.enabled
        }
        guard let json = PanelController.encode(payload) else { return }
        evaluate("window.Chatterkill && window.Chatterkill.config(\(json));")
    }

    private func evaluate(_ script: String) {
        guard let webView else { return }
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private static func encode(_ object: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "chatterkill",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }

        switch type {
        case "ready":
            if let pendingConfig { pushConfig(pendingConfig) }
        case "setThreshold":
            guard let key = body["key"] as? String else { return }
            let milliseconds: UInt64?
            if let raw = body["ms"] as? NSNumber {
                milliseconds = UInt64(max(0, raw.intValue))
            } else {
                milliseconds = nil
            }
            onSetThreshold?(key, milliseconds)
        case "done":
            close()
            onFinish?()
        case "openPermission":
            onOpenPermission?()
        default:
            break
        }
    }

    // MARK: - WKNavigationDelegate

    /// 只允许读 bundle 里的 web/ 目录，任何跳转/外链一律拦下。
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        let allowed = url.isFileURL && url.path.contains("/web/")
        decisionHandler(allowed ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let pendingConfig { pushConfig(pendingConfig) }
    }
}
