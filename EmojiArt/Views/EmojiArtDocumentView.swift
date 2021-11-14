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
                            .scaleEffect(selectedEmojis.isEmpty ? zoomScale : steadyStateZoomScale)
                            .position(convertFromEmojiCoordinatesForBackground((0, 0), in: geometry))
                    )
                    .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: tapToUnselectAllEmojis()))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
//                            .selectionEffect(for: emoji, in: selectedEmojis)
                            .overlay(
                                selectedEmojis.contains(emoji) ? RoundedRectangle(cornerRadius: 0).strokeBorder(lineWidth: 1.2).foregroundColor(.blue) : nil)

                            .scaleEffect(selectedEmojis.isEmpty ? zoomScale : selectedEmojis.contains(emoji) ? zoomScale : steadyStateZoomScale)
                            .position(position(for: emoji, in: geometry))
//                            .gesture(panEmojiGesture(on: emoji).exclusively(before: selectionGesture(on: emoji)))
                            .gesture(selectionGesture(on: emoji).simultaneously(with: selectedEmojis.contains(emoji) ? panEmojiGesture(on: emoji) : nil))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(zoomGesture().simultaneously(with: gestureEmojiPanOffset == CGSize.zero ? panGesture() : nil))
        }
    }
    
    // MARK: - Select/Diselect
    

    @State private var selectedEmojis = Set<EmojiArtModel.Emoji>()
    
    private func selectionGesture(on emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture()
            .onEnded {
                withAnimation {
                    selectedEmojis.toggleMembership(of: emoji)
                    
                }
                print(selectedEmojis)
            }
    }
    
    private func tapToUnselectAllEmojis() -> some Gesture {
        TapGesture()
            .onEnded {
                withAnimation {
                    selectedEmojis = []
                }
                print(selectedEmojis)
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
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale)
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
            x: (location.x - center.x - panOffset.width - gestureEmojiPanOffset.width) / zoomScale,
            y: (location.y - center.y - panOffset.height - gestureEmojiPanOffset.height) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }

    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width + gestureEmojiPanOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height + gestureEmojiPanOffset.height
        )
    }
    
    private func convertFromEmojiCoordinatesForBackground(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }

    // MARK: - Zooming
    
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                if selectedEmojis.isEmpty {
                    steadyStateZoomScale *= gestureScaleAtEnd
                } else {
                    for emoji in selectedEmojis {
                        document.scaleEmoji(emoji, by: gestureScaleAtEnd)
                    }
                }
                print(selectedEmojis)
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(image: document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(image: UIImage?, in size: CGSize) {
        if let image = image, image.size.height > 0, image.size.width > 0,
           size.width > 0, size.height > 0  {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            
            steadyStatePanOffset = CGSize.zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    // MARK: - Panning
    
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        //        (steadyStatePanOffset + gesturePanOffset)  // absolute version
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset =  steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    @GestureState var gestureEmojiPanOffset: CGSize = CGSize.zero
//    private var previousDistance: CGSize = CGSize.zero
    
    private func panEmojiGesture(on emoji: EmojiArtModel.Emoji) -> some Gesture {
        DragGesture()
            .updating($gestureEmojiPanOffset) { latestDragGestureValue, gestureEmojiPanOffset, _ in
//                for emoji in selectedEmojis {
//                    document.moveEmoji(emoji, by: (latestDragGestureValue.distance / zoomScale))
//                    print(latestDragGestureValue.startLocation)
//                }
                gestureEmojiPanOffset = latestDragGestureValue.distance
            }
            .onEnded { finalDragGestureValue in
                for emoji in selectedEmojis {
                    document.moveEmoji(emoji, by: finalDragGestureValue.distance / zoomScale)
                }
                print(finalDragGestureValue.startLocation)
                print(selectedEmojis)
                print("ITS NOT ENDING")
            }
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
