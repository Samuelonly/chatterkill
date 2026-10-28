//
//  KeyMap.swift
//  Chatterkill
//
//  Key-code table. Single source of truth for both directions (code <-> name),
//  shared by the engine and the web panel.
//  Forked from Debounce/KeyCodeMapper.swift (MIT, Timo Leisengang).
//

import Foundation
import Carbon.HIToolbox

struct KeyDefinition {
    let name: String
    let code: CGKeyCode
}

enum KeyMap {

    /// 108 键标准全尺寸布局用到的全部键。
    /// 注意：PC 键盘上的 PrtSc / ScrLk / Pause 在 macOS 下分别上报 F13 / F14 / F15，
    /// 所以面板上这三颗按 F13/F14/F15 处理，不单独占 keycode。
    static let definitions: [KeyDefinition] = [
        // 字母
        KeyDefinition(name: "A", code: CGKeyCode(kVK_ANSI_A)),
        KeyDefinition(name: "B", code: CGKeyCode(kVK_ANSI_B)),
        KeyDefinition(name: "C", code: CGKeyCode(kVK_ANSI_C)),
        KeyDefinition(name: "D", code: CGKeyCode(kVK_ANSI_D)),
        KeyDefinition(name: "E", code: CGKeyCode(kVK_ANSI_E)),
        KeyDefinition(name: "F", code: CGKeyCode(kVK_ANSI_F)),
        KeyDefinition(name: "G", code: CGKeyCode(kVK_ANSI_G)),
        KeyDefinition(name: "H", code: CGKeyCode(kVK_ANSI_H)),
        KeyDefinition(name: "I", code: CGKeyCode(kVK_ANSI_I)),
        KeyDefinition(name: "J", code: CGKeyCode(kVK_ANSI_J)),
        KeyDefinition(name: "K", code: CGKeyCode(kVK_ANSI_K)),
        KeyDefinition(name: "L", code: CGKeyCode(kVK_ANSI_L)),
        KeyDefinition(name: "M", code: CGKeyCode(kVK_ANSI_M)),
        KeyDefinition(name: "N", code: CGKeyCode(kVK_ANSI_N)),
        KeyDefinition(name: "O", code: CGKeyCode(kVK_ANSI_O)),
        KeyDefinition(name: "P", code: CGKeyCode(kVK_ANSI_P)),
        KeyDefinition(name: "Q", code: CGKeyCode(kVK_ANSI_Q)),
        KeyDefinition(name: "R", code: CGKeyCode(kVK_ANSI_R)),
        KeyDefinition(name: "S", code: CGKeyCode(kVK_ANSI_S)),
        KeyDefinition(name: "T", code: CGKeyCode(kVK_ANSI_T)),
        KeyDefinition(name: "U", code: CGKeyCode(kVK_ANSI_U)),
        KeyDefinition(name: "V", code: CGKeyCode(kVK_ANSI_V)),
        KeyDefinition(name: "W", code: CGKeyCode(kVK_ANSI_W)),
        KeyDefinition(name: "X", code: CGKeyCode(kVK_ANSI_X)),
        KeyDefinition(name: "Y", code: CGKeyCode(kVK_ANSI_Y)),
        KeyDefinition(name: "Z", code: CGKeyCode(kVK_ANSI_Z)),

        // 数字与符号
        KeyDefinition(name: "0", code: CGKeyCode(kVK_ANSI_0)),
        KeyDefinition(name: "1", code: CGKeyCode(kVK_ANSI_1)),
        KeyDefinition(name: "2", code: CGKeyCode(kVK_ANSI_2)),
        KeyDefinition(name: "3", code: CGKeyCode(kVK_ANSI_3)),
        KeyDefinition(name: "4", code: CGKeyCode(kVK_ANSI_4)),
        KeyDefinition(name: "5", code: CGKeyCode(kVK_ANSI_5)),
        KeyDefinition(name: "6", code: CGKeyCode(kVK_ANSI_6)),
        KeyDefinition(name: "7", code: CGKeyCode(kVK_ANSI_7)),
        KeyDefinition(name: "8", code: CGKeyCode(kVK_ANSI_8)),
        KeyDefinition(name: "9", code: CGKeyCode(kVK_ANSI_9)),
        KeyDefinition(name: "`", code: CGKeyCode(kVK_ANSI_Grave)),
        KeyDefinition(name: "-", code: CGKeyCode(kVK_ANSI_Minus)),
        KeyDefinition(name: "=", code: CGKeyCode(kVK_ANSI_Equal)),
        KeyDefinition(name: "[", code: CGKeyCode(kVK_ANSI_LeftBracket)),
        KeyDefinition(name: "]", code: CGKeyCode(kVK_ANSI_RightBracket)),
        KeyDefinition(name: "\\", code: CGKeyCode(kVK_ANSI_Backslash)),
        KeyDefinition(name: ";", code: CGKeyCode(kVK_ANSI_Semicolon)),
        KeyDefinition(name: "'", code: CGKeyCode(kVK_ANSI_Quote)),
        KeyDefinition(name: ",", code: CGKeyCode(kVK_ANSI_Comma)),
        KeyDefinition(name: ".", code: CGKeyCode(kVK_ANSI_Period)),
        KeyDefinition(name: "/", code: CGKeyCode(kVK_ANSI_Slash)),

        // 控制键
        KeyDefinition(name: "Esc", code: CGKeyCode(kVK_Escape)),
        KeyDefinition(name: "Tab", code: CGKeyCode(kVK_Tab)),
        KeyDefinition(name: "CapsLock", code: CGKeyCode(kVK_CapsLock)),
        KeyDefinition(name: "Return", code: CGKeyCode(kVK_Return)),
        KeyDefinition(name: "Shift", code: CGKeyCode(kVK_Shift)),
        KeyDefinition(name: "RightShift", code: CGKeyCode(kVK_RightShift)),
        KeyDefinition(name: "Control", code: CGKeyCode(kVK_Control)),
        KeyDefinition(name: "RightControl", code: CGKeyCode(kVK_RightControl)),
        KeyDefinition(name: "Option", code: CGKeyCode(kVK_Option)),
        KeyDefinition(name: "RightOption", code: CGKeyCode(kVK_RightOption)),
        KeyDefinition(name: "Command", code: CGKeyCode(kVK_Command)),
        KeyDefinition(name: "RightCommand", code: CGKeyCode(kVK_RightCommand)),
        KeyDefinition(name: "Space", code: CGKeyCode(kVK_Space)),
        KeyDefinition(name: "Delete", code: CGKeyCode(kVK_Delete)),
        KeyDefinition(name: "ForwardDelete", code: CGKeyCode(kVK_ForwardDelete)),

        // 功能键
        KeyDefinition(name: "F1", code: CGKeyCode(kVK_F1)),
        KeyDefinition(name: "F2", code: CGKeyCode(kVK_F2)),
        KeyDefinition(name: "F3", code: CGKeyCode(kVK_F3)),
        KeyDefinition(name: "F4", code: CGKeyCode(kVK_F4)),
        KeyDefinition(name: "F5", code: CGKeyCode(kVK_F5)),
        KeyDefinition(name: "F6", code: CGKeyCode(kVK_F6)),
        KeyDefinition(name: "F7", code: CGKeyCode(kVK_F7)),
        KeyDefinition(name: "F8", code: CGKeyCode(kVK_F8)),
        KeyDefinition(name: "F9", code: CGKeyCode(kVK_F9)),
        KeyDefinition(name: "F10", code: CGKeyCode(kVK_F10)),
        KeyDefinition(name: "F11", code: CGKeyCode(kVK_F11)),
        KeyDefinition(name: "F12", code: CGKeyCode(kVK_F12)),
        KeyDefinition(name: "F13", code: CGKeyCode(kVK_F13)),
        KeyDefinition(name: "F14", code: CGKeyCode(kVK_F14)),
        KeyDefinition(name: "F15", code: CGKeyCode(kVK_F15)),

        // 导航区
        KeyDefinition(name: "Help", code: CGKeyCode(kVK_Help)),
        KeyDefinition(name: "Home", code: CGKeyCode(kVK_Home)),
        KeyDefinition(name: "End", code: CGKeyCode(kVK_End)),
        KeyDefinition(name: "PageUp", code: CGKeyCode(kVK_PageUp)),
        KeyDefinition(name: "PageDown", code: CGKeyCode(kVK_PageDown)),
        KeyDefinition(name: "UpArrow", code: CGKeyCode(kVK_UpArrow)),
        KeyDefinition(name: "DownArrow", code: CGKeyCode(kVK_DownArrow)),
        KeyDefinition(name: "LeftArrow", code: CGKeyCode(kVK_LeftArrow)),
        KeyDefinition(name: "RightArrow", code: CGKeyCode(kVK_RightArrow)),

        // 小键盘
        KeyDefinition(name: "Keypad0", code: CGKeyCode(kVK_ANSI_Keypad0)),
        KeyDefinition(name: "Keypad1", code: CGKeyCode(kVK_ANSI_Keypad1)),
        KeyDefinition(name: "Keypad2", code: CGKeyCode(kVK_ANSI_Keypad2)),
        KeyDefinition(name: "Keypad3", code: CGKeyCode(kVK_ANSI_Keypad3)),
        KeyDefinition(name: "Keypad4", code: CGKeyCode(kVK_ANSI_Keypad4)),
        KeyDefinition(name: "Keypad5", code: CGKeyCode(kVK_ANSI_Keypad5)),
        KeyDefinition(name: "Keypad6", code: CGKeyCode(kVK_ANSI_Keypad6)),
        KeyDefinition(name: "Keypad7", code: CGKeyCode(kVK_ANSI_Keypad7)),
        KeyDefinition(name: "Keypad8", code: CGKeyCode(kVK_ANSI_Keypad8)),
        KeyDefinition(name: "Keypad9", code: CGKeyCode(kVK_ANSI_Keypad9)),
        KeyDefinition(name: "KeypadClear", code: CGKeyCode(kVK_ANSI_KeypadClear)),
        KeyDefinition(name: "KeypadMultiply", code: CGKeyCode(kVK_ANSI_KeypadMultiply)),
        KeyDefinition(name: "KeypadPlus", code: CGKeyCode(kVK_ANSI_KeypadPlus)),
        KeyDefinition(name: "KeypadMinus", code: CGKeyCode(kVK_ANSI_KeypadMinus)),
        KeyDefinition(name: "KeypadDivide", code: CGKeyCode(kVK_ANSI_KeypadDivide)),
        KeyDefinition(name: "KeypadEnter", code: CGKeyCode(kVK_ANSI_KeypadEnter)),
        KeyDefinition(name: "KeypadDecimal", code: CGKeyCode(kVK_ANSI_KeypadDecimal)),
        KeyDefinition(name: "KeypadEquals", code: CGKeyCode(kVK_ANSI_KeypadEquals))
    ]

    static let nameByCode: [CGKeyCode: String] = {
        var map: [CGKeyCode: String] = [:]
        for definition in definitions {
            map[definition.code] = definition.name
        }
        return map
    }()

    static let codeByName: [String: CGKeyCode] = {
        var map: [String: CGKeyCode] = [:]
        for definition in definitions {
            map[definition.name] = definition.code
        }
        return map
    }()

    static func name(for code: CGKeyCode) -> String {
        nameByCode[code] ?? "Key\(code)"
    }

    static func code(for name: String) -> CGKeyCode? {
        codeByName[name]
    }
}
