//
//  CaptionGuidesView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/24/23.
//

import SwiftUI

struct CaptionGuidesView: View {
    let tones: [ToneModel]
    let includeEmojis: Bool
    let includeHashtags: Bool
    let captionLength: String
    
    private func mapCaptionLength() -> CaptionLengths? {
        guard let captionLengthMap = captionLengths.first(where: { $0.type == captionLength }) else { return nil }
        return captionLengthMap
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    Text("What makes a caption stand out?")
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.title2)
                    
                    Text("Unlock your Social Media Potential with CapGen! ⚡\n\nAI-Powered Caption Generation with custom options for tone, length, emojis, hashtags, and platforms.\n\nStand out with personalized captions that speak to your unique style and audience. 🔥")
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.headlineLightSm)
                        .lineSpacing(8)
                        .padding(.bottom, 20)
                    
                    Text("Your captions guide")
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.title2)
                    
                    if (!self.tones.isEmpty) {
                        ToneDescriptionView(tones: self.tones)
                    }
                    
                    SettingsDescriptionView(image: self.includeEmojis ? "yes-emoji" : "no-emoji", text: self.includeEmojis ? "Emojis are included" : "No emojis included", description: self.includeEmojis ? "Some emojis are included in your captions." : "No emojis are included in your captions.")
                    
                    SettingsDescriptionView(image: self.includeHashtags ? "yes-hashtag" : "no-hashtag", text: self.includeHashtags ? "Hashtags are included" : "No hashtags included", description: self.includeHashtags ? "Some hashtags are included in your captions." : "No hashtags are included in your captions.")
                    
                    if (self.mapCaptionLength() != nil) {
                        SettingsDescriptionView(image: self.mapCaptionLength()!.type, text: self.mapCaptionLength()!.title, description: "Your captions have \(self.mapCaptionLength()!.value).", widthOffset: 10)
                    }
                    
                }
                .padding()
                .padding(.top, 25)
            }
           
        }
    }
}

struct CaptionGuidesView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionGuidesView(tones: [tones[0], tones[2]], includeEmojis: true, includeHashtags: false, captionLength: "veryShort")
        
        CaptionGuidesView(tones: [tones[0]], includeEmojis: true, includeHashtags: false, captionLength: "veryLong")
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
            .environmentObject(OpenAIConnector())
    }
}

struct ToneDescriptionView: View {
    let tones: [ToneModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ForEach(Array(tones.enumerated()), id: \.element) { index, tone in
                    HStack(spacing: 0) {
                        Text(tone.icon)
                            .font(.system(size: 30))
                            .padding(.leading, -2)
                        
                        Text("\(tone.title)")
                            .font(.ui.title5)
                            .foregroundColor(.ui.richBlack)
                        
                        if (index < tones.count - 1) {
                            Text(" &")
                                .font(.ui.title5)
                                .foregroundColor(.ui.richBlack)
                        }
                    }
                }
            }
            
        
            
            if (tones.count > 1) {
                Text("Your captions convey a \(tones[0].description.dropLast().lowercased()) tone with a \(tones[1].description.dropLast().lowercased()) disposition.")
                    .font(.ui.headlineLightSm)
                    .foregroundColor(.ui.richBlack)
                    .lineSpacing(8)
            } else {
                Text("Your captions convey a \(tones[0].description.dropLast().lowercased()) tone.")
                    .font(.ui.headlineLightSm)
                    .foregroundColor(.ui.richBlack)
                    .lineSpacing(8)
            }
        }
        
    }
}

struct SettingsDescriptionView: View {
    let image: String
    let text: String
    let description: String
    var widthOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 3) {
                Image(image)
                    .resizable()
                    .frame(width: 30 - widthOffset, height: 30)
                    .padding(.trailing, 5)
                
                Text(text)
                    .font(.ui.title5)
                    .foregroundColor(.ui.richBlack)
            }
            
            Text(description)
                .font(.ui.headlineLightSm)
                .foregroundColor(.ui.richBlack)
        }
        
    }
}
