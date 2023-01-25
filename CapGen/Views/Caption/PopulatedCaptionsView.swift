//
//  PopulatedCaptionsView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/20/23.
//

import SwiftUI

extension View {
    func customCardStyle(viewHeight: CGFloat) -> some View {
        return self
            .frame(width: SCREEN_WIDTH * 0.9, height: viewHeight + 150)
            .padding()
            .shadow(
                color: Color.ui.richBlack.opacity(0.5),
                radius: 2,
                x: 1,
                y: 2
            )
    }
}

// The ViewSizeKey and ViewGeometry are used to calculate size of Views
struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct ViewGeometry: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ViewSizeKey.self, value: geometry.size)
        }
    }
}

struct PopulatedCaptionsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var firestore: FirestoreManager
    
    @State var textSize: CGSize = .zero
    @State var platformSelected: String = ""
    @State var showCaptionsView: Bool = false
    @State var unparsedCaptionStr: String? = ""
    @State var filteredCaptionsGroup: [AIRequest] = []
    @State var platforms: [String] = []
    @State var showDeleteModal: Bool = false
    @State var currentCaptionSelected: AIRequest = AIRequest()
    
    // Mapper for caption view
    @State var tones: [ToneModel] = []
    @State var captionLength: String = ""
    @State var prompt: String = ""
    @State var includeEmojis: Bool = false
    @State var includeHashtags: Bool = false
    @State var savedCaptions: [GeneratedCaptions] = []
    
    private func mapCaptionConfigurations(element: AIRequest) {
        // Generate a string to parse captions
        for (index, caption) in element.captions.enumerated() {
            self.unparsedCaptionStr! += "\n\(index). \(caption.description)"
        }
        // Generate the last string to parse title
        self.unparsedCaptionStr! += "\n6. \(element.title)"
        
        // Map necessary configurations to view
        self.tones = element.tones
        self.captionLength = element.captionLength
        self.prompt = element.prompt
        self.includeEmojis = element.includeEmojis
        self.includeHashtags = element.includeHashtags
        self.savedCaptions = element.captions
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            VStack {
                Color.ui.lavenderBlue.ignoresSafeArea(.all)
                    .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT * (SCREEN_HEIGHT < 700 ? 0.2 : 0.15))
                    .overlay(
                        VStack(spacing: 0) {
                            BackArrowView {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                            .frame(maxWidth: SCREEN_WIDTH, alignment: .leading)
                            .frame(height: 10)
                            .padding(.leading, 15)
                            .padding(.bottom, 20)
                            .padding(.top, 15)
                            
                            PlatformHeaderView(platforms: platforms, platformSelected: $platformSelected)
                            
                            Spacer()
                        }
                    )

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(filteredCaptionsGroup) { element in
                            ZStack(alignment: .topLeading) {
                                StackedCardsView(viewHeight: self.textSize.height)
                                VStack(alignment: .leading, spacing: 20) {
                                    CardTitleHeaderView(title: element.title) {
                                        // Edit caption group
                                        self.mapCaptionConfigurations(element: element)
                                        self.showCaptionsView = true
                                    } share: {
                                        
                                    } delete: {
                                        self.showDeleteModal = true
                                        self.currentCaptionSelected = element
                                    }
                                    
                                    Button {
                                        self.mapCaptionConfigurations(element: element)
                                        self.showCaptionsView = true
                                        
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(element.prompt)
                                                .font(.ui.bodyLarge)
                                                .foregroundColor(.ui.cultured)
                                                .lineLimit(Int(SCREEN_HEIGHT / 180))
                                                .multilineTextAlignment(.leading)
                                                .lineSpacing(3)
                                                .background(ViewGeometry())
                                                .onPreferenceChange(ViewSizeKey.self) {
                                                    self.textSize = $0 // get size of text view
                                                }
                                            
                                            Spacer()
                                            
                                            // Bottom area of group
                                            HStack(spacing: 5) {
                                                // Tones indicator
                                                ConfigurationIndicatorsView(element: element)
                                                
                                                Spacer()
                                                
                                                Text(element.dateCreated)
                                                    .foregroundColor(.ui.cultured)
                                                    .font(.ui.headlineMd)
                                                
                                            }
                                        }
                                    }
                                }
                                .padding(40)
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showCaptionsView) {
            CaptionView(captionStr: $unparsedCaptionStr, tones: self.tones, captionLength: captionLength, prompt: prompt, includeEmojis: includeEmojis, includeHashtags: includeHashtags, savedCaptions: savedCaptions, isEditing: true, platform: platformSelected) {
                // On exit
                self.unparsedCaptionStr?.removeAll()
            }
            .navigationBarBackButtonHidden(true)
        }
        .onReceive(AuthManager.shared.userManager.$user) { user in
            // This creates a set from an array of platforms by mapping the platform property of each object
            // Use this to retrieve all social media network platforms in an array
            if (user != nil) {
                let value = user!.captionsGroup
                let platformSet = Set(value.map { $0.platform })
                self.platforms = Array(platformSet).sorted()
                
                if (!self.platforms.isEmpty) {
                    self.platformSelected = self.platforms[0] // initiate the first item to be selected by default
                    self.filteredCaptionsGroup = value.filter { $0.platform == self.platformSelected }
                }
            }
            
        }
        .onChange(of: self.platformSelected) { value in
            // Filter to the selected social media network platform
            let captionsGroup = AuthManager.shared.userManager.user?.captionsGroup as? [AIRequest] ?? []
            self.filteredCaptionsGroup = captionsGroup.filter { $0.platform == value }
        }
        .modalView(horizontalPadding: 40, show: $showDeleteModal) {
            DeleteModalView(title: "Deleting Captions", subTitle: "You’re about to delete these captions. This action cannot be undone. Are you sure? 🫢", lottieFile: "crane_hand_lottie", showView: $showDeleteModal, onDelete: {
                firestore.onCaptionsGroupDelete(for: AuthManager.shared.userManager.user?.id ?? nil, element: self.currentCaptionSelected, captionsGroup: filteredCaptionsGroup)
            })
        } onClickExit: {
            self.showDeleteModal = false
        }
    }
}

struct PopulatedCaptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PopulatedCaptionsView()
        
        PopulatedCaptionsView()
            .previewDevice("iPhone 13 Pro Max")
        
        PopulatedCaptionsView()
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct PlatformPillsBtnView: View {
    var title: String
    var isToggled: Bool
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 100)
                .fill(isToggled ? Color.ui.middleBluePurple : Color.ui.cultured)
                .shadow(
                    color: Color.ui.richBlack.opacity(isToggled ? 0 : 0.3),
                    radius: 2,
                    x: 1,
                    y: 2
                )
                .frame(width: SCREEN_WIDTH / 2.4, height: 40)
                .overlay(
                    HStack {
                        Image(title)
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        
                        Text(title)
                            .font(.ui.headline)
                            .foregroundColor(isToggled ? .ui.cultured : .ui.cadetBlueCrayola)
                    }
                    
                )
        }
    }
}

struct PlatformHeaderView: View {
    let platforms: [String]
    @Binding var platformSelected: String
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(platforms, id: \.self) { platform in
                        PlatformPillsBtnView(title: platform, isToggled: platformSelected == platform) {
                            self.platformSelected = platform
                        }
                        .id(platform)
                    }
                }
                .padding()
            }
            .onChange(of: self.platformSelected) { value in
                withAnimation {
                    scrollProxy.scrollTo(value, anchor: .center)
                }
            }
        }
    }
}

struct StackedCardsView: View {
    let viewHeight: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.darkSalmon)
                .offset(x: 10, y: 10)
                .customCardStyle(viewHeight: viewHeight)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.middleYellowRed)
                .offset(x: 5, y: 5)
                .customCardStyle(viewHeight: viewHeight)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.middleBluePurple)
                .customCardStyle(viewHeight: viewHeight)
        }
    }
}

struct CardTitleHeaderView: View {
    let title: String
    var edit: () -> Void
    var share: () -> Void
    var delete: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.ui.title)
                .foregroundColor(.ui.cultured)
                .scaledToFit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Spacer()
            
            // Edit button
            CustomMenuPopup(edit: {
                edit()
            }, share: {
                share()
            }, delete: {
                delete()
            })
        }
    }
}

struct ConfigurationIndicatorsView: View {
    let element: AIRequest
    
    var body: some View {
        HStack {
            // Tones
            if (!element.tones.isEmpty) {
                CircularTonesView(tones: element.tones)
            }
            
            // Emojis
            CircularView(image: element.includeEmojis ? "yes-emoji" : "no-emoji")
            
            // Hashtags
            CircularView(image: element.includeHashtags ? "yes-hashtag" : "no-hashtag")
            
            // Caption length
            CircularView(image: element.captionLength, imageWidth: 20)
        }
        
    }
}

enum CircularViewSize {
    case large, regular
}

struct CircularTonesView: View {
    let tones: [ToneModel]
    @State var circularViewSize: CircularViewSize = .regular
    
    private func calculateSize() -> CGFloat {
        if circularViewSize == .regular {
            return 35.0
        }
        
        return 50.0
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.ui.cultured)
                .frame(width: calculateSize(), height: calculateSize())
            
            // If there are 2 tones for a caption group, then group them together in one circle
            if (!tones.isEmpty) {
                if (tones.count > 1) {
                    Text(tones[0].icon)
                        .font(circularViewSize == .regular ? .ui.headlineSm : Font.ui.headline)
                        .offset(x: -5, y: -5)
                    
                    Text(tones[1].icon)
                        .font(circularViewSize == .regular ? .ui.headlineSm : Font.ui.headline)
                        .offset(x: 5, y: 3)
                } else {
                    Text(tones[0].icon)
                        .font(.ui.title2)
                }
            }
        }
    }
}

struct CircularView: View {
    let image: String
    @State var imageWidth: CGFloat?
    @State var circularViewSize: CircularViewSize = .regular
    
    private func calculateSize() -> CGFloat {
        if circularViewSize == .regular {
            return 35.0
        }
        
        return 50.0
    }
    
    var body: some View {
        // Emojis
        ZStack {
            Circle()
                .fill(Color.ui.cultured)
                .frame(width: calculateSize(), height: calculateSize())
            
            Image(image)
                .resizable()
                .frame(width: calculateSize() - (imageWidth != nil ? imageWidth! : 15), height: calculateSize() - 15)
        }
    }
}
