//
//  UtilityExtensions.swift
//  EmojiArt
//
//  Created by sun on 2021/11/09.
//

import SwiftUI

extension Collection where Element: Identifiable {
    func index(matching element: Element) -> Self.Index? {
        firstIndex { $0.id == element.id }
    }
}


extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
