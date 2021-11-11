//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by sun on 2021/11/09.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    private let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .overlay(
                        OptionalImage(uiImage: document.backgroundImage)
                    )
                ForEach(document.emojis) { emoji in
                    Text(emoji.text)
                        .font(.system(size: fontSize(for: emoji)))
                        .position(position(for: emoji, in: geometry))
                }
            }
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
        }
    }
    
    // MARK: - Drag and Drop
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL))
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(String(emoji), at: convertToEmojiCoordinates(location, in: geometry), size: defaultEmojiFontSize)
                }
            }
        }
        
        return found
    }
    
    // MARK: - Positioning/Sizing Emoji
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (Int, Int) {
        let center = geometry.frame(in: .local).center
        let location = (
            x: location.x - center.x,
            y: location.y - center.y
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(location.x),
            y: center.y + CGFloat(location.y)
        )
    }
    
    // MARK: - palette
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmojis = "🥰🐷☀️💚🥝🍓🍕🧁🏀🎹✈️🏖🔮🎈🎁🚙🏋️‍♀️☃️🌈🎃💄🤷‍♀️🌸🍀🍄⭐️🌳🎂🎷🎨🏠⛰💡📀💎"
}

















struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        let document = EmojiArtDocument()
        EmojiArtDocumentView(document: document)
    }
}
