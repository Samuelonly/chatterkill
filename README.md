# Chatterkill · 抖抑

<p align="center">
  <img src="docs/icon.png" width="256" alt="Chatterkill icon">
</p>

![Chatterkill 108 键检测面板](docs/panel.png)

**中文**

Chatterkill（中文名「抖抑」）是一个 macOS 菜单栏小工具，治键盘的两种坏毛病：太灵的键，轻点一下就冒出两三个字符（`apple` → `apppple`，俗称**连击 / 按键双击**）；太肉的键，不按到底不出字。它在系统层把多余的按键吞掉，再给你一张 108 键检测面板——哪个键在犯病一目了然，点一下那个键就能单独给它调延迟，好键不受牵连。

**English**

Chatterkill is a tiny macOS menu-bar utility that stops **keyboard double typing** (key chatter): keys too sensitive, where a light tap fires `apple` → `apppple`, and keys too mushy to register unless pressed hard. It swallows the extra presses at the system event level and hands you a 108-key tester panel, so the misbehaving keys are plain to see — click one to give it its own delay, without slowing down the rest.

## 亮点 / Highlights

**中文**

- **系统级拦截**：多余按键在到达应用之前就被吞掉；每个键可单独设 20–300 ms 判定窗口
- **108 键可视化面板**：未测 / 正常 / 连击 / 迟钝 / 固件不上报，五种状态一眼分清，点键帽就是设置
- **纯本地，不联网**：菜单第一行永远写着「仅在本地不联网」；不上报、不记录按键内容，代码全部开源
- **两个保险开关**：
  - 「拦截密码框」默认**开**——密码框里同样防连击；关掉则密码输入完全放行（代价：密码框里可能照样连击）
  - 「拦截功能键」默认**关**——⌘⇧⌥⌃ / Fn / F1–F15 永不吞，双击 Fn 呼出听写、Cmd 快捷键万无一失
- **装完即忘**：开机自启默认开启；界面语言跟系统走（中文 / English）；常驻约 30–50 MB，空闲 CPU ≈ 0%
- **Apple Silicon 专用**，macOS 14+，只需「辅助功能」一个权限

**English**

- **System-level blocking** — extra presses are swallowed before apps ever see them; per-key windows from 20–300 ms
- **108-key visual tester** — untested / normal / chatter / slow / never-reported, five states at a glance; the panel *is* the settings
- **Local only, no network** — the menu says it on row one; no telemetry, no keystroke logging, fully open source
- **Two safety toggles**
  - "Block Password Fields", **on** by default — password fields get the same protection; turn it off and password input passes through untouched (chatter included)
  - "Block Modifier & Function Keys", **off** by default — ⌘⇧⌥⌃ / Fn / F1–F15 are never swallowed; double-tap Fn dictation and Cmd shortcuts stay safe
- **Set and forget** — launch at login on by default; UI language follows the system (中文 / English); ~30–50 MB resident, idle CPU ≈ 0%
- **Apple Silicon only**, macOS 14+, one permission: Accessibility

## 为什么做这个 / Why

一罐可乐洒在了机械键盘上。晾干之后，有几个键开始不听话：有的轻碰一下就打出两三个字符，有的按到底才肯出字。GitHub 上的开源去抖工具确实有效，但它说不出「哪个键病得最重」，我只能盲猜着一个个试。所以我重写了它：留下那套拦截引擎，写了一块会自己点亮键帽的检测面板——发现问题，和解决问题，在同一个窗口里。

A can of Coke tipped over onto my mechanical keyboard. Once it dried, a few keys started misbehaving: some fired two or three characters at the lightest touch, others refused to register unless pressed to the bottom. The open-source debounce tool I found worked, but it couldn't tell me *which* key was the worst offender — I was testing blind, one key at a time. So I rewrote it: kept the blocking engine, and built a panel that lights up the key caps themselves. Finding the problem and fixing it, in the same window.

## 面板五色 / The five states

**中文**

1. **未测（深灰）** —— 这次检测里还没按过，没有数据。
2. **正常（绿）** —— 间隔和按住时长都在阈值内，这个键是好的。
3. **太快 · 连击（红）** —— 两次按下的间隔短于阈值，多出来的那次已经被吞掉。
4. **松手过慢（蓝）** —— 按住时间明显超过正常点按，就是那种要用力才出字的键。
5. **固件层不上报（暗）** —— 这类键 macOS 根本收不到（比如 Fn），测不了也拦不了。

**English**

1. **Untested (grey)** — not pressed yet in this session, no data.
2. **Normal (green)** — interval and hold time both inside the threshold; the key is fine.
3. **Too fast / chatter (red)** — the second press landed inside the threshold and was already swallowed.
4. **Slow release (blue)** — held far longer than a normal tap; the kind of key that only fires when you press hard.
5. **Never reported (dark)** — the key never reaches macOS (e.g. Fn), so it can't be measured or blocked.

## 使用 / Use

1. 菜单栏图标 → **打开检测面板**。| menu-bar icon → **Open Tester**.
2. 正常打字，怀疑的键多按几下。| Type normally; tap the suspect keys a few times.
3. 红键 = 连击，蓝键 = 迟钝，绿键 = 正常。| Red = chattering, blue = mushy, green = fine.
4. 点键帽 → 单独调 20–300 ms，「用全局值」恢复默认。| Click a cap → 20–300 ms; "Use global" resets it.
5. 关窗即走：面板连同辅助进程一起销毁，拦截引擎继续常驻。| Close the window: the panel and its helper are torn down, the engine stays.

菜单栏里还能看**今日 / 累计拦截**（今日零点自动清零）。| The menu also shows **blocked today / blocked total** (today resets at midnight).

配置文件：`~/Library/Application Support/Chatterkill/config.json` | Config lives at that path.

## 安装 / Install

1. 从 [Releases](https://github.com/Samuelonly/chatterkill/releases) 下载 `Chatterkill.dmg`，把 **Chatterkill** 拖进 `/Applications`。| Download `Chatterkill.dmg` from [Releases](https://github.com/Samuelonly/chatterkill/releases) and drag **Chatterkill** into `/Applications`.
2. 首次打开请**右键 → 打开**（未公证，双击会被 Gatekeeper 挡住）。代码全部开源，运行前可以先读。| First launch: **right-click → Open** (not notarized; Gatekeeper blocks a plain double-click). Everything is open source — read it before you run it.
3. 或者终端去掉隔离标记：| Or clear the quarantine flag:

   ```bash
   xattr -d com.apple.quarantine /Applications/Chatterkill.app
   ```

4. 授予**辅助功能**：系统设置 → 隐私与安全性 → 辅助功能 → 勾上 Chatterkill。| Grant **Accessibility**: System Settings → Privacy & Security → Accessibility → enable Chatterkill.
5. 菜单栏图标 → 确认「开机自启」已勾上。| Menu-bar icon → make sure **Launch at Login** is checked.

打开后没有 Dock 图标，它只活在菜单栏里；双击 App 图标会直接弹出检测面板。| No Dock icon — it lives in the menu bar only. Double-clicking the app reopens the tester.

## 已知限制 / Known limits

- 密码框、`sudo`、Touch ID 属于 Secure Input，macOS 会主动停用事件监听：「拦截密码框」开着（默认）时 Chatterkill 会重新挂上监听继续拦；关掉则完全尊重系统——密码输入原样放行，离开密码框自动恢复。| Under Secure Input (password fields, `sudo`, Touch ID) macOS suspends the event tap: with "Block Password Fields" on (default) Chatterkill re-attaches and keeps blocking; off, it respects the suspension — password input passes through, and global monitoring resumes automatically when you leave the field.
- α 版只吞多余按键，不给迟钝键补发字符。| The alpha only swallows extra presses; it won't re-send characters for mushy keys.
- 自己重编译会改变签名，辅助功能旧授权失效，需删掉重新勾一次。| Rebuilding changes the signature, which invalidates the Accessibility grant — remove the stale entry and grant again.

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

## 版本更新 / Changelog

### v0.5.0

- 全新家族化图标：酒瓶开关红底 squircle，App 内 icns 与 README 同步换新
- 面板视觉统一：红以图标红（#ca0600）为基准，绿以键位描边绿为基准——KILL 标识、完成按钮、图例方块、监听中绿点、最近按键时间、阈值滑块全部对齐，色彩规范见 docs/COLORS.md
- README 按 0.5.0 全面重写：功能补齐（两个保险开关）、文案精简、效果图与配色同步
- 面板修复与排版：清掉布局数据笔误产生的幽灵「a」键；两个 Del 改为 ⌫ / ⌦ 消除歧义；窗口高度贴合内容、间距统一 10px，不再有大片留白；未测键描边换淡暖绿
- Brand-new unified icon: swing-top bottle on a red squircle — same icon now in the app bundle (icns) and the README
- Panel visuals unified: red follows the icon red (#ca0600), green follows the key-outline green — KILL wordmark, Done button, legend swatches, listening dot, last-key time and threshold slider all match; see docs/COLORS.md
- README rewritten for 0.5.0: feature-complete (both safety toggles), tighter copy, screenshot in the new palette
- Panel fixes & layout: removed the phantom "a" key caused by a layout-data typo; the two Del keys are now ⌫ / ⌦; window height hugs the content with a uniform 10px rhythm — no more dead space; untested keys get a faint warm-green hairline

### v0.4.0

- 菜单第一段就一行：“仅在本地不联网”，行首一颗小绿点
- 菜单勾选全部改成小绿点：选中=有点，未选=空白，不再有对勾
- 新增开关“拦截功能键”，默认关；不吞 ⌘⇧⌥⌃ / Fn / F1–F15，连按 Fn 听写安全
- 新增开关“拦截密码框”，默认开；关掉后密码输入完全放行
- 拦截中：“暂停拦截”那行亮绿点；暂停后熄灭
- “打开检测面板”独立一段，行首键盘图标，不看文字也认得出
- 阈值滑块下限降到 20ms

- First menu row: "Local only, no network" with a small green dot
- Menu ticks are green dots now: on = dot, off = blank; no more checkmarks
- New toggle "Block Modifier & Function Keys", off by default — ⌘⇧⌥⌃ / Fn / F1–F15 are never swallowed
- New toggle "Block Password Fields", on by default; turn it off and password input passes through
- A green dot on the Pause/Start row means blocking is live
- "Open Tester" gets its own section, led by a keyboard icon
- Threshold slider minimum lowered to 20ms

### v0.3.0

- 密码框 / Secure Input 下自动降级为本地监听，面板内打字仍可检测
- 菜单栏新增隐私提示：🔒 仅本地处理，不联网
- 阈值滑块下限从 50ms 降至 30ms

- Auto-fallback to local monitor during Secure Input; panel still works within Chatterkill's own windows
- Menu bar privacy notice: 🔒 Local only, no network
- Threshold slider minimum lowered from 50ms to 30ms

### v0.2.0

- 108 键检测面板 + WKWebView 桥接
- 五态可视化（未测 / 正常 / 连击 / 迟钝 / 固件不上报）
- 点键改阈值，JSON 配置落盘
- 开机自启 / 中英自动适配

- 108-key tester panel with WKWebView bridge
- Five-state visualization (untested / normal / chatter / slow / locked)
- Click-to-set threshold, JSON config persistence
- Launch at login / auto bilingual (zh/en)

## License

MIT. See [LICENSE](LICENSE).
