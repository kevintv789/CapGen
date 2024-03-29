//
//  CaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Heap
import NavigationStack
import SwiftUI

func mapShareableData(caption: String, platform: String?) -> ShareableData {
    var item: String {
        if let platform = platform {
            return """
            Behold the precious caption I generated from ⚡CapGen⚡ for my \(platform) post!

            "\(caption)"
            """
        }

        return """
        Behold the precious caption I generated from ⚡CapGen⚡!

        "\(caption)"
        """
    }

    let newShareableData = ShareableData(item: item, subject: "Check out my caption from CapGen!")
    return newShareableData
}

struct CaptionView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var firestore: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionVm: CaptionViewModel
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel
    @EnvironmentObject var photosSelectionVm: PhotoSelectionViewModel

    // navigation
    @State var router: Router? = nil
    var navContext: NavigationContext = .prompt

    // for sharing within custom menu
    @State var shareableData: ShareableData?

    // default card colors
    @State var cardColorFill: [Color] = [.ui.middleYellowRed, .ui.darkSalmon, .ui.middleBluePurple, .ui.frenchBlueSky, .ui.lightCyan]

    @State var isLoading: Bool = false

    @State var saveError: Bool = false
    @State var showCaptionsGuideModal: Bool = false
    @State var isEditingTitle: Bool = false
    
    @State var isFullScreenImage: Bool = false
    
    @State var showImagePrefModal: Bool = false

    // Variables below are specifically for going through saved captions screen
    var isEditing: Bool?
    var onBackBtnClicked: (() -> Void)?

    @ScaledMetric var scaledSize: CGFloat = 1

    private func dynamicViewPop() {
        if !isLoading {
            if onBackBtnClicked != nil {
                onBackBtnClicked!()
                navStack.pop(to: .previous)
            } else {
                navStack.pop(to: .view(withId: HOME_SCREEN))
            }

            captionVm.resetEditedCaption()
        }
    }

    /**
     Maps the caption that is potentially edited to the caption view model.
     */
    private func mapCaptionToBeEdited(index: Int, caption: String) {
        // Create caption model object with required elements
        captionVm.selectedCaption = CaptionModel(captionLength: genPromptVm.captionLengthType, captionDescription: caption, includeEmojis: genPromptVm.includeEmojis, includeHashtags: genPromptVm.includeHashtags, prompt: genPromptVm.promptInput, title: openAiConnector.captionGroupTitle, tones: genPromptVm.selectdTones, color: cardColorFill[index].toHex() ?? "", completePrompt: openAiConnector.prompt)

        // On click, store a reference to the caption that will potentially be edited
        captionVm.editedCaption = EditedCaption(index: index, text: caption)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.cultured.ignoresSafeArea(.all)

            VStack(alignment: .leading) {
                BackArrowView {
                    dynamicViewPop()
                }
                .padding(.leading, 15)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
                        HStack {
                            if navContext == .image, let uiImage = photosSelectionVm.uiImage {
                                ImageThumbnailView(uiImage: uiImage) {
                                    // on thumbnail press, show full image
                                    withAnimation {
                                        isFullScreenImage.toggle()
                                    }
                                }
                               
                                Spacer()
                            }
                            
                            
                            EditableTitleView(isError: $saveError, isEditing: self.$isEditingTitle, context: navContext)
                                .padding(.bottom, 15)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            // Animatable instructional text
                            AnimatableInstructionView()
                            
                            // Preferences button
                            if navContext == .image {
                                Button {
                                    showImagePrefModal.toggle()
                                } label: {
                                    HStack(spacing: 5) {
                                        Text("Image Preferences")
                                            .foregroundColor(.ui.middleBluePurple)
                                            .font(.ui.title4)
                                        
                                        Image("cogwheel-purple")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top)
                                .padding(.leading, 5)
                            }
                          

                            Spacer()

                            ForEach(Array(self.openAiConnector.captionsGroupParsed.enumerated()), id: \.element) { index, caption in
                                Button {
                                    withAnimation {
                                        // Set a delay to show bottom sheet
                                        // This is a direct result of having the custom menu opened right before pressing this button
                                        // which will result in a "View is already presented" error
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            self.mapCaptionToBeEdited(index: index, caption: caption)
                                            self.captionVm.isCaptionSelected = true
                                        }

                                        Heap.track("onClick CaptionView - Clicked on caption card, show Optimzation bottom sheet view", withProperties: ["caption": caption, "index": index])
                                        Haptics.shared.play(.soft)
                                    }
                                } label: {
                                    if index < Constants.TOTAL_CAPTIONS_GENERATED {
                                        CaptionCard(caption: caption, colorFilled: $cardColorFill[index], shareableData: self.$shareableData,
                                                    edit: {
                                                        // edit
                                                        self.mapCaptionToBeEdited(index: index, caption: caption)

                                                        // on click, take user to edit caption screen
                                                        self.navStack.push(EditCaptionView(context: .regular))

                                                    }, onMenuOpen: {
                                                        self.shareableData = mapShareableData(caption: caption, platform: nil)
                                                    })
                                                    .padding(10)
                                    }
                                }
                            }
                        }
                        .simultaneousGesture(TapGesture().onEnded { _ in
                            self.isEditingTitle = false
                        })

                        Spacer()
                    }
                    .padding()
                }
            }
        }
        // show full image on click
        .overlay(
            FullScreenImageOverlay(isFullScreenImage: $isFullScreenImage, image: photosSelectionVm.uiImage, imageHeight: .constant(nil))
        )
        .sheet(isPresented: $captionVm.isCaptionSelected) {
            CaptionOptimizationBottomSheetView(context: navContext)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showImagePrefModal) {
            ImagePreferenceModalView()
                .presentationDetents([.fraction(0.7)])
        }
        .onAppear {
            Heap.track("onAppear CaptionView - Captions generated", withProperties: ["captions": openAiConnector.captionsGroupParsed, "total_captions": openAiConnector.captionsGroupParsed.count])

            // Initialize router
            self.router = Router(navStack: self.navStack)

            // replace original parsed list with edited caption
            if !self.captionVm.editedCaption.text.isEmpty {
                self.openAiConnector.captionsGroupParsed[self.captionVm.editedCaption.index] = self.captionVm.editedCaption.text
            }
        }
    }
}

struct CaptionView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionView()
            .environmentObject(OpenAIConnector())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionViewModel())
            .environmentObject(GenerateByPromptViewModel())
            .environmentObject(PhotoSelectionViewModel())

        CaptionView()
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
            .environmentObject(OpenAIConnector())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionViewModel())
            .environmentObject(GenerateByPromptViewModel())
            .environmentObject(PhotoSelectionViewModel())
    }
}

struct EditableTitleView: View {
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @FocusState var isFocusOn: Bool
    @Binding var isError: Bool
    @Binding var isEditing: Bool
    var context: NavigationContext = .image

    var body: some View {
        HStack {
            if !isEditing && !isError {
                Text(openAiConnector.captionGroupTitle)
                    .font(.ui.title)
                    .foregroundColor(.ui.richBlack)
                    .frame(maxWidth: context == .prompt ? SCREEN_WIDTH * 0.8 : SCREEN_WIDTH * 0.7, alignment: .leading)
                    .lineLimit(context == .prompt ? 1 : 2)
                    .if(context == .prompt) { view in
                        return view
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                    }
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1))
                    .foregroundColor(isError ? Color.red : Color.ui.shadowGray)
                    .overlay(
                        TextField("", text: self.$openAiConnector.captionGroupTitle)
                            .focused($isFocusOn)
                            .font(.ui.title)
                            .foregroundColor(.ui.shadowGray)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: context == .prompt ? SCREEN_WIDTH * 0.8 : SCREEN_WIDTH * 0.7, alignment: .leading)
                            .lineLimit(1)
                            .submitLabel(.done)
                            .onSubmit {
                                isEditing.toggle()
                                isFocusOn.toggle()
                            }
                            .onChange(of: self.openAiConnector.captionGroupTitle, perform: { title in
                                if title.isEmpty || title == " " {
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
                Heap.track(isEditing ? "onClick CaptionView - Currently editing title" : "onClick CaptionView - Finished editing title, new title: \(openAiConnector.captionGroupTitle)")
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

struct AnimatableInstructionView: View {
    @ScaledMetric var scaledSize: CGFloat = 1

    // animating text
    @State var initialText: String = ""
    let finalText: String = "Go ahead, tap a card 😏"

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 100)
                .stroke(Color.ui.cultured, lineWidth: 4)
                .shadow(color: .ui.richBlack.opacity(0.5), radius: 4, x: 0, y: 2)

            RoundedRectangle(cornerRadius: 100)
                .fill(Color.ui.richBlack)

            AnimatedTextView(initialText: $initialText, finalText: self.finalText, isRepeat: false, timeInterval: 5, typingSpeed: 0.03)
                .font(.ui.graphikMedium)
                .foregroundColor(.ui.cultured)
        }
        .frame(width: 240 * scaledSize, height: 40 * scaledSize)
    }
}

struct CaptionCard: View {
    var caption: String
    @State private var phase = 0.0
    @Binding var colorFilled: Color
    @Binding var shareableData: ShareableData?

    var edit: (() -> Void)?
    var onMenuOpen: (() -> Void)?
    var onCopyAndGo: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.ui.lighterLavBlue, lineWidth: 2)

            RoundedRectangle(cornerRadius: 14)
                .fill(colorFilled)

            VStack(alignment: .trailing, spacing: 0) {
                HStack {
                    Text(caption.trimmingCharacters(in: .whitespaces))
                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 15))
                        .font(.ui.graphikRegular)
                        .lineSpacing(4)
                        .foregroundColor(.ui.richBlack)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    CustomMenuPopup(menuTheme: .dark, shareableData: $shareableData,
                                    socialMediaPlatform: .constant(nil), edit: {
                                        Heap.track("onClick CaptionView Custom Menu - Edit caption", withProperties: ["caption": caption])
                                        edit?()
                                    }, onMenuOpen: {
                                        onMenuOpen?()
                                    }, onCopyAndGo: {
                                        Heap.track("onClick CaptionView Custom Menu - Copy & Go action", withProperties: ["caption": caption])
                                        onCopyAndGo?()
                                    })
                                    .onTapGesture {}
                                    .frame(maxHeight: .infinity, alignment: .topTrailing)
                                    .padding(.trailing, -10)
                }
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
            if tones != nil && !self.tones!.isEmpty {
                CircularTonesView(tones: self.tones ?? [])
            }

            // Emojis
            CircularView(image: self.includeEmojis ?? false ? "yes-emoji" : "no-emoji")

            // Hashtags
            CircularView(image: self.includeHashtags ?? false ? "yes-hashtag" : "no-hashtag")

            // Caption length
            if self.captionLength != nil && !self.captionLength!.isEmpty {
                CircularView(image: self.captionLength!, imageWidth: 20)
            }
        }
    }
}
