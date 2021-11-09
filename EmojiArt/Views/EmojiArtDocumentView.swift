//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by sun on 2021/11/09.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            background
            pallete
        }
    }
    
    var background: some View {
        GeometryReader { geometry in
            ZStack {
                Color.yellow
                ForEach(document.emojis) { emoji in
                    Text(emoji.text)
                        .font(.system(size: fontSize(for: emoji)))
                        .position(position(for: emoji, in: geometry))
                }
            }
        }
    }
    
    var pallete: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(location.x),
            y: center.y + CGFloat(location.y)
        )
    }
    
    let testEmojis = "🥰🐷☀️💚🥝🍓🍕🧁🏀🎹✈️🏖🔮🎈🎁🚙🏋️‍♀️☃️🌈🎃💄🤷‍♀️🌸🍀🍄⭐️🌳🎂🎷🎨🏠⛰💡📀💎"
}

















struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        let document = EmojiArtDocument()
        EmojiArtDocumentView(document: document)
    }
}
