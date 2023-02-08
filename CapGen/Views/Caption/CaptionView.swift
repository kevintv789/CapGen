//
//  CaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import SwiftUI
import NavigationStack

func mapShareableData(caption: String, captionGroup: AIRequest?) -> ShareableData? {
    if (captionGroup != nil) {
        var item: String {
            """
            Behold the precious caption I generated from ⚡CapGen⚡ for my \(captionGroup!.platform)!
            
            "\(caption)"
            """
        }
        
        let newShareableData = ShareableData(item: item, subject: "Check out my caption from CapGen!")
        return newShareableData
    }
    
    return nil
}


struct CaptionView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionEditVm: CaptionEditViewModel
    @EnvironmentObject var captionConfigs: CaptionConfigsViewModel
    
    @State var router: Router? = nil
    
    @State var shareableData: ShareableData?
    @Binding var captionStr: String?
    @State var captionSelected: String = ""
    @State var cardColorFill: [Color] = [.ui.middleYellowRed, .ui.darkSalmon, .ui.middleBluePurple, .ui.frenchBlueSky, .ui.lightCyan]
    @State var isLoading: Bool = false
    
    @State var initialText: String = ""
    let finalText: String = "Tap a card to copy 😏"
    @State private var isTextCopied: Bool = false
    @State var saveError: Bool = false
    @State var showCaptionsGuideModal: Bool = false
    @State var isEditingTitle: Bool = false
    
    // Variables below are specifically for going through saved captions screen
    @State var mutableCaptionGroup: AIRequest?
    var savedCaptions: [GeneratedCaptions]?
    var isEditing: Bool?
    var platform: String
    var onBackBtnClicked: (() -> Void)?
    
    @ScaledMetric var animatedTextBorderWidth: CGFloat = 220
    @ScaledMetric var animatedTextBorderHeight: CGFloat = 40
    
    private func dynamicViewPop() {
        if (!self.isLoading) {
            if (onBackBtnClicked != nil) {
                onBackBtnClicked!()
                navStack.pop(to: .previous)
            } else {
                navStack.pop(to: .view(withId: HOME_SCREEN))
            }
            
            self.captionEditVm.resetCaptionView()
        }
    }

    func saveCaptions() {
        // Don't do anything if there's an error
        self.isLoading = true
        
        guard !self.saveError else {
            self.isLoading = false
            return
        }
        
        // Store caption group title and caption cards
        var mappedCaptions: [GeneratedCaptions] = []
        self.captionEditVm.captionsGroupParsed.forEach { caption in
            mappedCaptions.append(GeneratedCaptions(id: UUID().uuidString, description: caption))
        }
        
        // Retrieves necessary data to find and save document
        let userId = AuthManager.shared.userManager.user?.id as? String ?? nil
        let captionsGroup = AuthManager.shared.userManager.user?.captionsGroup as? [AIRequest] ?? []
        
        // Generate request model for saving new generated captions
        if (self.isEditing == nil || (self.isEditing != nil && !self.isEditing!)) {
            openAiConnector.generateNewRequestModel(title: self.captionEditVm.captionGroupTitle, captions: mappedCaptions)
            
            // Save new entry to database
            Task {
                await firestore.saveCaptions(for: userId, with: openAiConnector.requestModel, captionsGroup: captionsGroup) {
                    self.isLoading = false
                    self.captionConfigs.resetConfigs()
                    dynamicViewPop()
                }
            }
            
        } else {
            // Update caption group
            if (self.mutableCaptionGroup != nil && self.openAiConnector.mutableCaptionGroup != nil) {
                self.openAiConnector.updateMutableCaptionGroupWithNewCaptions(with: mappedCaptions, title: self.captionEditVm.captionGroupTitle)
                
                Task {
                    await firestore.saveCaptions(for: userId, with: self.openAiConnector.mutableCaptionGroup!, captionsGroup: captionsGroup) {
                        self.isLoading = false
                        self.captionConfigs.resetConfigs()
                        dynamicViewPop()
                   }
                }
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.cultured.ignoresSafeArea()
            Color.ui.lighterLavBlue.ignoresSafeArea().opacity(0.5)
               
            
            VStack(alignment: .leading) {
                BackArrowView() {
                    dynamicViewPop()
                }
                    .padding(.leading, 8)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
                        
                        EditableTitleView(isError: $saveError, isEditing: self.$isEditingTitle)
                            .padding(.bottom, 15)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            if (isEditing != nil && isEditing!) {
                                // Display saved prompt
                                if (self.mutableCaptionGroup?.prompt != nil) {
                                    Text(self.mutableCaptionGroup!.prompt)
                                        .padding(.bottom, 15)
                                        .font(.ui.headlineLight)
                                        .foregroundColor(.ui.richBlack)
                                }
                                
                                Button {
                                    self.showCaptionsGuideModal = true
                                    Haptics.shared.play(.soft)
                                } label: {
                                    // Display different settings for the captions
                                    CaptionSettingsView(prompt: mutableCaptionGroup?.prompt, tones: mutableCaptionGroup?.tones, includeEmojis: mutableCaptionGroup?.includeEmojis, includeHashtags: mutableCaptionGroup?.includeHashtags, captionLength: mutableCaptionGroup?.captionLength)
                                }
                                
                            }
                            
                            if (!isTextCopied && (isEditing == nil || !isEditing!)) {
                                RoundedRectangle(cornerRadius: 100)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4], dashPhase: 0))
                                    .foregroundColor(Color.ui.richBlack)
                                    .overlay(
                                        AnimatedTextView(initialText: $initialText, finalText: self.finalText, isRepeat: false, timeInterval: 5, typingSpeed: 0.03)
                                            .font(.ui.graphikMedium)
                                            .foregroundColor(.ui.richBlack)
                                            .frame(width: SCREEN_WIDTH, alignment: .center)
                                    )
                                    .frame(width: animatedTextBorderWidth, height: animatedTextBorderHeight)
                            }
                            Spacer()
                            
                            
                            ForEach(Array(self.captionEditVm.captionsGroupParsed.enumerated()), id: \.element) { index, caption in
                                Button {
                                    withAnimation {
                                        self.captionSelected = caption
                                        self.isTextCopied = true
                                        UIPasteboard.general.string = String(caption)
                                        Haptics.shared.play(.soft)
                                    }
                                } label: {
                                    if index < 5 {
                                        CaptionCard(caption: caption, isCaptionSelected: caption == captionSelected, colorFilled: $cardColorFill[index], shareableData: self.$shareableData,
                                        edit: {
                                            // edit
                                            self.captionEditVm.selectedIndex = index
                                            
                                            self.router?.toEditCaptionView(color: cardColorFill[index], title: self.captionEditVm.captionGroupTitle, platform: self.platform, caption: caption)
                                        }, onMenuOpen: {
                                            self.shareableData = mapShareableData(caption: caption, captionGroup: self.mutableCaptionGroup)
                                        })
                                        .padding(10)
                                        
                                    }
                                }
                            }
                        }
                        .simultaneousGesture(TapGesture().onEnded({ _ in
                            self.isEditingTitle = false
                        }))
                        
                        Spacer()
                        
                        SubmitButtonGroupView(onSaveClick: {
                            saveCaptions()
                            Haptics.shared.play(.soft)
                        }, onResetClick: {
                            dynamicViewPop()
                            Haptics.shared.play(.soft)
                        }, isLoading: self.$isLoading)
                        .padding(.top, 15)
                        
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showCaptionsGuideModal) {
            CaptionGuidesView(tones: self.mutableCaptionGroup?.tones ?? [], includeEmojis: self.mutableCaptionGroup?.includeEmojis ?? false, includeHashtags: self.mutableCaptionGroup?.includeHashtags ?? false, captionLength: self.mutableCaptionGroup?.captionLength ?? "")
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            
        }
        .onAppear() {
            logScreenAnalytics(for: "\(CaptionView.self)")
            if (self.openAiConnector.mutableCaptionGroup != nil) {
                self.mutableCaptionGroup = self.openAiConnector.mutableCaptionGroup!
            }
            
            // Initialize router
            self.router = Router(navStack: self.navStack)
            
            // Initial parse of raw text to captions
            if var originalString = captionStr, self.captionEditVm.captionsGroupParsed.isEmpty {
                
                // Removes trailing and leading white spaces
                originalString = captionStr!.trimmingCharacters(in: .whitespaces)
                
                let uniqueStr = UUID().uuidString
                
                let regex = try! NSRegularExpression(pattern: "(?m)^\\n\\d\\.|\\n\\d\\.", options: [])
                let modifiedString = regex.stringByReplacingMatches(in: originalString, options: [], range: NSRange(location: 0, length: originalString.utf16.count), withTemplate: uniqueStr)
                let stringArray = modifiedString.components(separatedBy: uniqueStr)
                var parsedArray = stringArray.filter({ ele in
                    return ele != "" && ele != "\n" && ele != "\n\n"
                })
                
                // Removing the first character because it is an empty space
                self.captionEditVm.captionGroupTitle = String(parsedArray.removeLast().trimmingCharacters(in: .whitespaces))
                
                self.captionEditVm.captionsGroupParsed = parsedArray.map { element in
                    // removing leading and trailing white spaces
                    return element.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        .onAppear() {
            // Secondary pull after caption has been edited
            if (!self.captionEditVm.captionsGroupParsed.isEmpty) {
                // Only runs if the value has been updated
                if (!self.captionEditVm.editableText.isEmpty && self.captionEditVm.captionsGroupParsed[self.captionEditVm.selectedIndex] != self.captionEditVm.editableText) {
                    self.captionEditVm.captionsGroupParsed[self.captionEditVm.selectedIndex] = self.captionEditVm.editableText
                    self.captionEditVm.editableText.removeAll()
                }
            }
        }
    }
}

struct CaptionView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionView(captionStr: .constant(" \n\n1. Loo🌈 \n2. My two doggos are having the time of their lives on the rainbow road - I wish I could join them! 🐶\n3. Nothing cuter than seeing two doggies playing in a rainbowNothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playin 🌈 \n4. My two furry friends enjoying the beautiful rainbow road 🤗 \n5. The best part of my day? Watching my two pups have a blast on the rainbow road 🤩 \n6. Two Pups, One Rainbow Roadddddd! 🌈"), platform: "Instagram")
            .environmentObject(OpenAIConnector())
            .environmentObject(CaptionEditViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionConfigsViewModel())
        
        CaptionView(captionStr: .constant("\n\n1. Loo🌈 \n2. My two doggos are having the time of their lives on the rainbow road - I wish I could join them! 🐶\n3. Nothing cuter than seeing two doggies playing in a rainbowNothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playin 🌈 \n4. My two furry friends enjoying the beautiful rainbow road 🤗 \n5. The best part of my day? Watching my two pups have a blast on the rainbow road 🤩 \n6. Two Pups, One Rainbow Roadddddd! 🌈"), platform: "Instagram")
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
            .environmentObject(OpenAIConnector())
            .environmentObject(CaptionEditViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionConfigsViewModel())
    }
}

struct EditableTitleView: View {
    @EnvironmentObject var captionEditVm: CaptionEditViewModel
    @FocusState var isFocusOn: Bool
    @Binding var isError: Bool
    
    @Binding var isEditing: Bool
    
    var body: some View {
        HStack {
            if (!isEditing && !isError) {
                Text("\(self.captionEditVm.captionGroupTitle)")
                    .font(.ui.title)
                    .foregroundColor(.ui.richBlack)
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                    .frame(width: SCREEN_WIDTH * 0.8, alignment: .leading)
                    .lineLimit(1)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1))
                    .foregroundColor(isError ? Color.red : Color.ui.shadowGray)
                    .overlay(
                        TextField("", text: self.$captionEditVm.captionGroupTitle)
                            .focused($isFocusOn)
                            .font(.ui.title)
                            .foregroundColor(.ui.shadowGray)
                            .minimumScaleFactor(0.5)
                            .frame(width: SCREEN_WIDTH * 0.8, alignment: .leading)
                            .lineLimit(1)
                            .submitLabel(.done)
                            .onSubmit {
                                isEditing.toggle()
                                isFocusOn.toggle()
                            }
                            .onChange(of: self.captionEditVm.captionGroupTitle, perform: { title in
                                if (title.isEmpty || title == " ") {
                                    isError = true
                                } else {
                                    isError = false
                                }
                            })
                    )
                    .frame(height: 45)
            }
            
            Spacer()
            
            Button {
                isEditing.toggle()
                isFocusOn.toggle()
                Haptics.shared.play(.soft)
            } label: {
                Image(systemName: "pencil")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.ui.richBlack)
            }
        }
        
    }
}

struct CaptionCard: View {
    var caption: String
    var isCaptionSelected: Bool
    @State private var phase = 0.0
    @Binding var colorFilled: Color
    @Binding var shareableData: ShareableData?
    
    var edit: () -> Void
    var onMenuOpen: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black, lineWidth: isCaptionSelected ? 2 : 1)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorFilled)
                )
            VStack(alignment: .trailing, spacing: 0) {
                HStack {
                    Text(caption.trimmingCharacters(in: .whitespaces))
                        .padding(EdgeInsets.init(top: 15, leading: 10, bottom: 15, trailing: 15))
                        .font(.ui.graphikRegular)
                        .lineSpacing(4)
                        .foregroundColor(.ui.richBlack)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    CustomMenuPopup(menuTheme: .dark, shareableData: $shareableData,
                    edit: {
                        edit()
                    }, onMenuOpen: {
                        onMenuOpen()
                    })
                    .onTapGesture { }
                    .frame(maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, -10)
                }
                
                
                if (isCaptionSelected) {
                    Text("Copied!")
                        .foregroundColor(Color.ui.richBlack)
                        .font(.ui.graphikMediumMed)
                        .padding(EdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10))
                        .frame(height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4], dashPhase: phase))
                                .foregroundColor(Color.ui.richBlack)
                                .onAppear {
                                    withAnimation(.linear.repeatForever(autoreverses: false).speed(0.1)) {
                                        phase += 20
                                    }
                                }
                            
                        )
                        .padding(EdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 12))
                }
            }
        }
    }
}

struct SubmitButtonGroupView: View {
    var onSaveClick: () -> Void
    var onResetClick: () -> Void
    
    @Binding var isLoading: Bool
    
    func displayBtnOverlay() -> some View {
        if (self.isLoading) {
            return AnyView(
                LottieView(name: "btn_loader", loopMode: .loop, isAnimating: true)
                    .frame(width: 100, height: 100)
            )
        } else {
            return AnyView(
                Text("Save")
                .foregroundColor(.ui.cultured)
                .font(.ui.title2)
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Button {
                self.onSaveClick()
            } label: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ui.darkerPurple)
                    .frame(width: SCREEN_WIDTH * 0.85, height: 55)
                    .shadow(color: Color.ui.shadowGray, radius: 2, x: 3, y: 4)
                    .overlay(displayBtnOverlay())
                
            }
            .disabled(self.isLoading)
            
            Button {
                self.onResetClick()
            } label: {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.ui.darkerPurple, lineWidth: 1)
                    .frame(width: SCREEN_WIDTH * 0.85, height: 55)
                    .shadow(color: Color.ui.shadowGray, radius: 1, x: 2, y: 1)
                    .overlay(
                        Text("Reset")
                            .foregroundColor(Color.ui.darkerPurple)
                            .font(.ui.title2)
                    )
            }
        }
    }
}

struct CaptionSettingsView: View {
    let prompt: String?
    let tones: [ToneModel]?
    let includeEmojis: Bool?
    let includeHashtags: Bool?
    let captionLength: String?
    
    var body: some View {
        // Display saved configurations
        HStack {
            // Tones
            if (tones != nil && !self.tones!.isEmpty) {
                CircularTonesView(tones: self.tones ?? [])
            }
            
            // Emojis
            CircularView(image: self.includeEmojis ?? false ? "yes-emoji" : "no-emoji")

            // Hashtags
            CircularView(image: self.includeHashtags ?? false ? "yes-hashtag" : "no-hashtag")
            
            // Caption length
            if (self.captionLength != nil && !self.captionLength!.isEmpty) {
                CircularView(image: self.captionLength!, imageWidth: 20)
            }
           
        }
    }
}
