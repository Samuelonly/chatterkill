# PROGRESS

> 每一步开新会话都先读这个文件。只改本段文件，能跑的别碰，编译不过就回滚。

## 当前状态

| 段 | 内容 | 状态 |
|---|---|---|
| A | 引擎 + 菜单栏 + JSON 配置 | ✅ 已编译、已运行、配置已落盘 |
| B | 108 键检测面板 + WKWebView | ✅ 已完成，浏览器实测通过（无 JS 报错、标签不裁切） |
| C | 桥接消息 + 五态 + 点键改阈值 | ✅ 代码已接，**待真机点按验收** |
| D | 开机自启 / 中英自动适配 / 图标 | ✅ 代码与图标已完成，**待重启验收** |
| E | 验收 + DMG | 🟡 DMG 脚本就绪，压测与重启验收未做 |

## 关键事实（别重复踩）

- **这台机器没有 Xcode**，只有 CommandLineTools（Swift 6.4，SDK macOS 27）。
  所以 `Debounce.xcodeproj` 不能 `xcodebuild`，改走 SwiftPM + 手工组装 `.app`。
- 上游 Debounce **没有开机自启**，`SMAppService` 这一段是本项目自己加的。
- α 版**只需要 Accessibility 一个权限**；Input Monitoring 是 1.0「补发」才需要。
- `CGEventTap` 只监听 `keyDown/keyUp`，不监听 `flagsChanged`，所以 Command/Shift/Option 永远吞不到。
- 面板关闭走 `PanelController.close()`：停加载 → 摘 message handler → 视图摘除 → 置 nil → 窗口释放。
  少一步 R1 就不达标。

## 已验证

- `swift build -c release` 通过；`dist/Chatterkill.app` 为 **arm64**，ad-hoc 签名成功。
- 启动后菜单栏图标在、进程常驻；`~/Library/Application Support/Chatterkill/config.json` 正常生成。
- 面板在 Chromium 里实测：108 键布局、按键高亮、侧栏时间戳、统计卡、点击弹阈值面板均正常。
- 空闲实测：**CPU 0.0%**，RSS ≈ **48 MB**（含 WebKit/AppKit 框架的常驻映射；
  PRD 里写的“几 MB”是拍的数字，README/PROGRESS 以实测为准，别再写几 MB）。
- `dist/Chatterkill.dmg` 已生成，约 **1.5 MB**（PRD 估的 10MB 偏大，实测很小）。
- 已装到 `/Applications/Chatterkill.app` 并以普通进程启动；`SMAppService.mainApp.status = 1`（enabled），
  **开机自启注册成功**。自启逻辑改为「每次启动自愈」：配置要自启 + 在 /Applications + 系统未注册 → 补注册，
  不再依赖 `hasCompletedOnboarding`（之前从 dist 目录跑过一次就把标记置了，导致装进 /Applications 后漏注册）。

## 待办（按顺序）

1. **真机拦键验收（A/C）**：在 /Applications 里运行 → 勾辅助功能 → 打 `apple letter 000`，
   看连击是否被压住；调 W=200ms 后连按不再冒字。
2. **重启验收（R3）**：重启 Mac 后不点图标直接打字，确认已在拦截。
3. **R1 资源验收**：开关面板 10 次，用活动监视器确认 `WebContent` 秒退、RSS 回落、空闲 CPU 0.0%。
4. **压测（R2）**：连续打字 1 小时，看平均 CPU < 1%、内存不涨。
5. 跑 `./scripts/create-dmg.sh` 出包，补 LICENSE 文件（MIT，含上游版权声明）。
6. 发 GitHub：README 已就绪，仓库 owner 建议 `com.eviduunce.chatterkill`。

## 已知取舍

- 面板键位是**标准 108 键布局**，不读取用户真实键盘（PRD 允许：引擎只认键码）。
- PrtSc / ScrLk / Pause 在 macOS 上报为 F13/F14/F15，面板按此映射。
- 蓝灯（迟钝）目前是启发式：按住 ≥1200ms 才标蓝，阈值 `ChatterBlocker.slowHoldMs` 可调。
- `config.json` 的 `perKey` 用可读键名（`"W": 200`），不是 `kVK_ANSI_W`，便于手改。
