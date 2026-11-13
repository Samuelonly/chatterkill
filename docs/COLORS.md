# Chatterkill 色彩规范 / Color Spec

> v0.5.0 起生效。面板全部颜色定义在 `Resources/web/index.html` 的 `:root` CSS 变量里，改色只改那一处。
> In effect since v0.5.0. All panel colors live in the `:root` CSS variables in `Resources/web/index.html`.

## 品牌基准色 / Brand anchors

| 色 / Color | 值 / Value | 来源 / Source | 用途 / Used for |
|---|---|---|---|
| **品牌红 Brand Red** | `#ca0600` rgb(202,6,0) | App 图标（酒瓶开关）背景红，从原图取样 / Sampled from the app icon (swing-top bottle) background | 连击键红色描边及光晕、图例「太快 / 连击」方块 / Chatter key outline & glow, legend "too fast / chatter" swatch |
| **品牌绿 Brand Green** | `#30d158` rgb(48,209,88) | 键盘「正常」键位描边绿 / The key-outline green of "normal" keys | 正常键描边、KILL 标识、完成按钮、监听中绿点、图例「正常」方块、最近按键时间、阈值滑块、键位徽标点 / Normal key outline, KILL wordmark, Done button, listening dot, legend "normal" swatch, last-key time, threshold slider, key badges |

## 状态色 / State colors

| 状态 / State | 值 / Value | 备注 / Notes |
|---|---|---|
| 正常 normal | `rgba(48,209,88,.65)` 描边 / outline，外发光 `.28`、内发光 `.12` | 品牌绿的透明派生 / Derived alpha of brand green |
| 太快 / 连击 chatter | `var(--red)` = `#ca0600`，光晕 `rgba(202,6,0,.55)`、内发光 `.22` | 品牌红 / Brand red |
| 松手过慢 slow | `#0a84ff`（系统蓝） | 保持不变 / Unchanged |
| 未测试 untested | `#5a5a5c` + `rgba(100,210,255,.22)` 内描边 | 灰 / Gray |
| 固件不上报 not reported | `#5a5a5c` @ 40% 透明 | 灰 / Gray |

## 完成按钮 / Done button（品牌绿深色派生 / dark derivations of brand green）

- 底色 background `#0a6e2e`，描边 border `#0f8a3a`，悬停 hover `#0c8032`

## 辅助色 / Auxiliary

| 用途 | 值 |
|---|---|
| 权限修复提醒 / permission-fix pill | `#ffd60a` |
| 背景 / background | `#1c1c1e`，面板 `#242426`，键帽 `#2c2c2e` → `#3a3a3c` |

## 历史 / History

- v0.5.0 之前面板混用 teal 青 `#00d5d5` 与系统红 `#ff453a`，v0.5.0 起废弃，统一为上述两把基准尺。
- Before v0.5.0 the panel mixed teal `#00d5d5` and system red `#ff453a`; both are retired in v0.5.0 in favor of the two brand anchors above.
