//
//  CaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import SwiftUI

struct CaptionView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var firestore: FirestoreManager
    
    @State var backBtnClicked: Bool = false
    @Binding var captionStr: String?
    @State var captionsParsed: [String] = []
    @State var captionsTitle: String = ""
    @State var captionSelected: String = ""
    @State var cardColorFill: [Color] = [.ui.middleYellowRed, .ui.darkSalmon, .ui.middleBluePurple, .ui.frenchBlueSky, .ui.lightCyan]
    
    @State var initialText: String = ""
    let finalText: String = "Tap a card to copy 😏"
    @State private var isTextCopied: Bool = false
    @State var saveError: Bool = false
    @State var showCaptionsGuideModal: Bool = false
    
    // Variables below are for the caption edit view
    @State var showEditCaptionView: Bool = false
    @State var captionToEdit: String = ""
    @State var selectedColorForEdit: Color = .clear
    
    // Variables below are specifically for going through saved captions screen
    var tones: [ToneModel]?
    var captionLength: String?
    var prompt: String?
    var includeEmojis: Bool?
    var includeHashtags: Bool?
    var savedCaptions: [GeneratedCaptions]?
    var isEditing: Bool?
    
    var platform: String
    
    var onBackBtnClicked: (() -> Void)?
    
    private func dynamicViewPop() {
        if (onBackBtnClicked != nil) {
            onBackBtnClicked!()
            self.presentationMode.wrappedValue.dismiss()
        } else {
            backBtnClicked = true
        }
    }
    
    func saveCaptions() {
        // Don't do anything if there's an error
        guard !self.saveError else { return }
        
        // Store caption group title and caption cards
        var mappedCaptions: [GeneratedCaptions] = []
        self.captionsParsed.forEach { caption in
            mappedCaptions.append(GeneratedCaptions(description: caption))
        }
        
        openAiConnector.generateNewRequestModel(title: self.captionsTitle, captions: mappedCaptions)
        
        // Save to database
        let userId = AuthManager.shared.userManager.user?.id as? String ?? nil
        
        let captionsGroup = AuthManager.shared.userManager.user?.captionsGroup as? [AIRequest] ?? []
        
        firestore.saveCaptions(for: userId, with: openAiConnector.requestModel, captionsGroup: captionsGroup) {
            dynamicViewPop()
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.cultured.ignoresSafeArea()
            Color.ui.lighterLavBlue.ignoresSafeArea().opacity(0.5)
            
            VStack(alignment: .leading) {
                BackArrowView { dynamicViewPop() }
                    .padding(.leading, 8)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
                        
                        EditableTitleView(title: $captionsTitle, isError: $saveError)
                            .padding(.bottom, 15)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            if (isEditing != nil && isEditing!) {
                                // Display saved prompt
                                if (prompt != nil) {
                                    Text(prompt!)
                                        .padding(.bottom, 15)
                                        .font(.ui.headlineLight)
                                        .foregroundColor(.ui.richBlack)
                                }
                                
                                Button {
                                    self.showCaptionsGuideModal = true
                                } label: {
                                    // Display different settings for the captions
                                    CaptionSettingsView(prompt: prompt, tones: tones, includeEmojis: includeEmojis, includeHashtags: includeHashtags, captionLength: captionLength)
                                }
                                
                            }
                            
                            if (!isTextCopied && (isEditing == nil || !isEditing!)) {
                                RoundedRectangle(cornerRadius: 100)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4], dashPhase: 0))
                                    .foregroundColor(Color.ui.richBlack)
                                    .overlay(
                                        AnimatedTextView(initialText: $initialText, finalText: self.finalText, isRepeat: self.showEditCaptionView ? false : true, timeInterval: 5, typingSpeed: 0.05)
                                            .font(.ui.graphikMedium)
                                            .foregroundColor(.ui.richBlack)
                                            .frame(width: SCREEN_WIDTH, alignment: .center)
                                    )
                                    .frame(width: 220, height: 40)
                            }
                            Spacer()
                            
                            
                            ForEach(Array(captionsParsed.enumerated()), id: \.element) { index, caption in
                                Button {
                                    withAnimation {
                                        self.captionSelected = caption
                                        self.isTextCopied = true
                                        UIPasteboard.general.string = String(caption)
                                    }
                                } label: {
                                    if index < 5 {
                                        CaptionCard(caption: caption, isCaptionSelected: caption == captionSelected, colorFilled: $cardColorFill[index])
                                        {
                                            // edit
                                            self.captionToEdit = caption
                                            self.selectedColorForEdit = cardColorFill[index]
                                            self.showEditCaptionView = true
                                           
                                        } share: {
                                            // share
                                        }
                                        .padding(10)
                                        
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        SubmitButtonGroupView(onSaveClick: {
                            saveCaptions()
                        }, onResetClick: {
                            dynamicViewPop()
                        })
                        .padding(.top, 15)
                        
                    }
                    .padding()
                }
            }
            
            
        }
        .navigationDestination(isPresented: $showEditCaptionView) {
            if (!captionToEdit.isEmpty) {
                EditCaptionView(bgColor: self.selectedColorForEdit, captionTitle: self.captionsTitle, platform: self.platform, caption: self.captionToEdit)
                    .navigationBarBackButtonHidden(true)
            } else {
                EmptyView()
            }
            
        }
        .sheet(isPresented: $showCaptionsGuideModal) {
            CaptionGuidesView(tones: self.tones ?? [], includeEmojis: self.includeEmojis ?? false, includeHashtags: self.includeHashtags ?? false, captionLength: self.captionLength ?? "")
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            
        }
        .navigationDestination(isPresented: $backBtnClicked) {
            HomeView(promptText: openAiConnector.requestModel.prompt, platformSelected: socialMediaPlatforms[0].title)
                .navigationBarBackButtonHidden(true)
        }
        .onAppear() {
            self.captionToEdit = ""
            
            if let originalString = captionStr {
                
                let uniqueStr = UUID().uuidString
                
                let regex = try! NSRegularExpression(pattern: "(?m)^\\n\\d\\.|\\n\\d\\.", options: [])
                let modifiedString = regex.stringByReplacingMatches(in: originalString, options: [], range: NSRange(location: 0, length: originalString.utf16.count), withTemplate: uniqueStr)
                let stringArray = modifiedString.components(separatedBy: uniqueStr)
                var parsedArray = stringArray.filter({ ele in
                    return ele != "" && ele != "\n" && ele != "\n\n"
                })
                
                // Removing the first character because it is an empty space
                self.captionsTitle = String(parsedArray.removeLast().trimmingCharacters(in: .whitespaces))
                
                self.captionsParsed = parsedArray.map { element in
                    // removing leading and trailing white spaces
                    return element.trimmingCharacters(in: .whitespaces)
                }
            }
        }
    }
}

struct CaptionView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionView(captionStr: .constant("\n\n1. Lo 🐶\n3. Nothing cuter than Nothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playinseeing two doggies playing in a rainbow 🌈 \n4. My two furry friends enjoying the beautiful rainbow road 🤗 \n5. The best part of my day? Watching my two pups have a blast on the rainbow road 🤩 \n6. 🌈"), platform: "Instagram")
            .environmentObject(OpenAIConnector())
        
        CaptionView(captionStr: .constant("\n\n1. Loo🌈 \n2. My two doggos are having the time of their lives on the rainbow road - I wish I could join them! 🐶\n3. Nothing cuter than seeing two doggies playing in a rainbowNothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playinNothing cuter than seeing two doggies playin 🌈 \n4. My two furry friends enjoying the beautiful rainbow road 🤗 \n5. The best part of my day? Watching my two pups have a blast on the rainbow road 🤩 \n6. Two Pups, One Rainbow Roadddddd! 🌈"), platform: "Instagram")
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
            .environmentObject(OpenAIConnector())
    }
}

struct EditableTitleView: View {
    @Binding var title: String
    @Binding var isError: Bool
    
    @State var isEditing: Bool = false
    
    var body: some View {
        HStack {
            if (!isEditing && !isError) {
                Text("\(title)")
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
                        TextField("", text: $title)
                            .font(.ui.title)
                            .foregroundColor(.ui.shadowGray)
                            .minimumScaleFactor(0.5)
                            .frame(width: SCREEN_WIDTH * 0.8, alignment: .leading)
                            .lineLimit(1)
                            .onChange(of: title, perform: { title in
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
    
    var edit: () -> Void
    var share: () -> Void
    
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
                    
                    CustomMenuPopup(menuTheme: .dark,
                    edit: {
                        edit()
                    }, share: {
                        share()
                    })
                    .onTapGesture { }
                    .frame(maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 18)
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
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Button {
                self.onSaveClick()
            } label: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ui.darkerPurple)
                    .frame(width: SCREEN_WIDTH * 0.85, height: 55)
                    .shadow(color: Color.ui.shadowGray, radius: 2, x: 3, y: 4)
                    .overlay(
                        Text("Save")
                            .foregroundColor(.ui.cultured)
                            .font(.ui.title2)
                    )
                
            }
            
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
            CircularView(image: self.captionLength ?? "veryShort", imageWidth: 20)
        }
    }
}
