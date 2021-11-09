//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by sun on 2021/11/09.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
