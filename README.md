# Chatterkill · 抖抑

![Chatterkill 108 键检测面板](docs/panel.png)

**中文介绍**

Chatterkill（中文名「抖抑」，抖音的抖、抑制的抑）是一个 macOS 菜单栏小工具，专门治机械键盘的两类坏毛病：一类键太灵，轻点一下就冒出两三个字符——`apple` 打成 `appppple`；另一类键太肉，不使劲按就不出字。它一边在系统层把这些多余的重复按键吞掉，一边给出一张 108 键的检测面板，让你一眼看出到底是哪几个键在犯病，并且可以只给那几个键单独设一个更宽的延迟，不牵连其他键。

**English**

Chatterkill is a tiny macOS menu-bar utility for mechanical keyboards that chatter: one press of a bouncy switch sends two or three characters (`apple` → `appppple`), while a mushy switch sends nothing until you hammer it. Chatterkill swallows those duplicate presses at the system event level, and ships a 108-key tester that shows exactly which keys are misbehaving — with per-key thresholds, so one bad key doesn't slow down the rest.

## 为什么做这个 / Why

我这把机械键盘用了几年，有几个键开始不听话：有的必须用力按到底才出字，有的轻轻一碰就变成连击。我试过在 GitHub 上找到的 [Eviduunce/Debounce](https://github.com/Eviduunce/Debounce) 来加延迟，确实有效，但它没法直观看出来“哪个键连击得最快”，我只能盲猜着一个个试。

所以我在它的启发下重写了这个软件：保留那套好用的拦截引擎思路，补上一块可以自己点亮键帽的检测面板，把“发现问题”和“解决问题”放进同一个窗口——点一下出问题的键，直接给它改延迟。

My mechanical keyboard is a few years old and some keys started misbehaving: a few only register when pressed hard, others double-tap from the lightest touch. I tried [Eviduunce/Debounce](https://github.com/Eviduunce/Debounce) to add a debounce delay, and it worked — but it couldn't show me *which* key was chattering fastest, so I was guessing one key at a time. Chatterkill is my take on it: same idea for the blocking engine, plus a tester panel that lights up the key caps themselves, so finding the problem and fixing it happen in one window.

## 五种颜色是什么意思 / The five states

| 状态 | 颜色 | 含义 | State | Color | Meaning |
|---|---|---|---|---|---|
| 未测 | 深灰 | 这次还没按过，没有数据 | untested | grey | never pressed in this session |
| 正常 | 绿 | 间隔和按住时长都在阈值内 | normal | green | interval and hold time within threshold |
| 太快 · 连击 | 红 | 两次按下的间隔短于阈值，多出来的那次被吞掉 | too fast / chatter | red | second press arrived inside the threshold and was swallowed |
| 迟钝 · 过久 | 蓝 | 按住时间明显超过正常点按，属于“要用力按”的那种键 | slow / held too long | blue | held far longer than a normal tap — the mushy key |
| 固件层不上报 | 暗 | 这类键 macOS 根本收不到（比如 Fn），无法测也无法拦 | not reported | dark | the key never reaches macOS (e.g. Fn), so it can't be measured or blocked |

## 几个刻意的设计 / Deliberate choices

- **功能键永远不拦。** `Command` / `Shift` / `Option` / `Control` / `Fn` 走的是 `flagsChanged`，引擎压根不监听这条通道，所以任何快捷键都不会被吞掉、不会被改。这是故意的，不是漏掉了。
- **没有全局快捷键。** 菜单里不带 `⌘E`、`⌘Q` 这类组合键，避免和别的软件抢键；要用就从菜单栏点。
- **检测面板就是设置。** 关掉面板时 WebView 连同它的辅助进程一起销毁，只剩拦截引擎常驻，不占 CPU、不占内存。检测完就关掉，是设计，不是妥协。
- **按系统语言自动切换。** 系统是中文就是中文，其他语言就是英文，没有语言选择器——全部文案也就十来个词。
- **开机即监听。** 开机自启默认开启，重启后不用点任何东西，拦截就在跑。

- **Function keys are never intercepted.** `Command` / `Shift` / `Option` / `Control` / `Fn` travel on `flagsChanged`, which the engine doesn't subscribe to at all — so no shortcut is ever swallowed or rewritten. Intentional.
- **No global shortcuts.** Nothing like `⌘E` or `⌘Q` is bound, so Chatterkill won't fight other apps for key combinations.
- **The tester *is* the settings window.** Closing it tears down the WebView and its helper process; only the event engine stays resident. One-shot calibration, zero idle cost.
- **Language follows the system.** Chinese system → Chinese UI, anything else → English. No language picker.
- **Blocking starts at login.** Launch-at-login is on by default.

## 系统要求 / Requirements

- **仅 Apple Silicon**（arm64，M1 及之后）。不提供 Intel 版本。| **Apple Silicon only** (arm64). No Intel build.
- macOS 14 Sonoma 或更新版本（在 macOS 27 上测过）。| macOS 14 or newer (tested up to macOS 27).
- **只需要一个权限：辅助功能（Accessibility）。** 不需要输入监控、不需要完全磁盘访问。| Only **Accessibility**. No Input Monitoring, no Full Disk Access.
- 常驻内存约 30–50 MB，空闲 CPU 基本是 0.0%。| ~30–50 MB resident, idle CPU ≈ 0.0%.
- 面板关闭后内存回落，WebView 进程退出。| Memory drops back once the panel closes; the WebContent process exits.

## 安装 / Install

1. 从 Releases 下载 `Chatterkill.dmg`，把 **Chatterkill** 拖进 `/Applications`。| Download `Chatterkill.dmg` from Releases and drag **Chatterkill** into `/Applications`.
2. 首次打开请**右键 → 打开**（没有公证签名，双击会被 Gatekeeper 挡住）。| First launch: **right-click → Open** (the build isn't notarized, so double-click is blocked by Gatekeeper).
3. 或者在终端里去掉隔离标记：| Or clear the quarantine flag:

   ```bash
   xattr -d com.apple.quarantine /Applications/Chatterkill.app
   ```

4. 系统会要求**辅助功能**权限：系统设置 → 隐私与安全性 → 辅助功能 → 勾上 Chatterkill。| Grant **Accessibility** when asked: System Settings → Privacy & Security → Accessibility → enable Chatterkill.
5. 菜单栏图标 → 确认「开机自启」已勾上。| Menu-bar icon → make sure **Launch at Login** is checked.

打开后没有 Dock 图标，它只活在菜单栏里。双击 App 图标会直接弹出检测面板。

There's no Dock icon; it lives in the menu bar only. Double-clicking the app icon reopens the tester panel.

## 使用 / Use

1. 菜单栏图标 → **打开检测面板…** | menu-bar icon → **Open Tester…**
2. 打一段字，或者把怀疑的键各按几下。| Type a paragraph, or tap each suspect key a few times.
3. 红键 = 连击，蓝键 = 迟钝，绿键 = 正常。| Red = chattering, blue = mushy, green = fine.
4. 点任意键帽 → 选 50–300 ms 的阈值；**Use global** 取消这个键的单独设置。| Click any key cap → pick a 50–300 ms threshold; **Use global** removes the per-key override.
5. 点 **DONE** 或关窗：面板销毁，只留引擎。| Click **DONE** or close the window: panel destroyed, engine stays.
6. 菜单栏里还能看到**今日字数 / 累计字数**两栏打字统计（跨天自动清零今日）。| The menu also shows **chars today / chars total** (today resets at midnight).

配置文件：`~/Library/Application Support/Chatterkill/config.json` | Config lives at the same path.

## 与上游的关系 / Credits

引擎和菜单栏外壳参考并改写了 [Eviduunce/Debounce](https://github.com/Eviduunce/Debounce)（MIT，作者 Timo Leisengang，版权声明保留在对应源文件里）；检测面板是全新写的。许可同为 MIT。

The event engine and menu-bar shell are forked from [Eviduunce/Debounce](https://github.com/Eviduunce/Debounce) (MIT, © Timo Leisengang; notices preserved in the forked files). The tester panel is an original build. MIT licensed.

## 从源码构建 / Build

不需要 Xcode，只要 Command Line Tools + Swift 6：| No Xcode needed — Command Line Tools plus Swift 6:

```bash
./scripts/build-app.sh      # -> dist/Chatterkill.app (arm64)
./scripts/create-dmg.sh     # -> dist/Chatterkill.dmg
```

脚本会在二进制里出现 `x86_64` 切片时直接失败——这个项目只发 arm64。| The build fails on purpose if the binary contains an `x86_64` slice.

## 目录 / Layout

```
Sources/Chatterkill/
  App/        main.swift, AppDelegate.swift, PanelController.swift
  Engine/     ChatterBlocker.swift, EventInterceptor.swift, KeyMap.swift, TypingCounter.swift
  Support/    ConfigStore.swift, PermissionHelper.swift, Loc.swift
Resources/
  web/        index.html, app.js      (tester panel, zero network calls)
  Info.plist, zh-Hans.lproj, AppIcon.icns
scripts/      build-app.sh, create-dmg.sh
```

## 已知限制 / Known limits

- 密码框、`sudo`、Touch ID 这类安全输入，macOS 会主动禁用事件监听，拦不了，这是系统行为。| macOS disables event taps around secure input (password fields, `sudo`, Touch ID). Not a bug.
- α 版本只做“吞掉多余按键”，不会帮迟钝的键补发字符。| The alpha only swallows extra presses; it won't re-send characters for mushy keys.
- 自己重新编译会改变签名，辅助功能里的旧授权会失效，需要删掉重新勾一次。| Rebuilding changes the signature, which invalidates the Accessibility grant — remove the stale entry and grant again.

## License

MIT. See [LICENSE](LICENSE).
