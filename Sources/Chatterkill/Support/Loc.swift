//
//  Loc.swift
//  Chatterkill
//
//  Zero-dependency i18n: follow the system language.
//  Chinese system -> Chinese, everything else -> English. No language picker.
//

import Foundation

enum Loc {
    static let isChinese: Bool = {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.lowercased().hasPrefix("zh")
    }()

    static func t(_ english: String, _ chinese: String) -> String {
        isChinese ? chinese : english
    }
}
