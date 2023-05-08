//
//  EditCaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/25/23.
//

import Combine
import Heap
import NavigationStack
import SwiftUI
import UIKit

struct EditCaptionView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionVm: CaptionViewModel
    @EnvironmentObject var searchVm: SearchViewModel
    @EnvironmentObject var photoSelectionVm: PhotoSelectionViewModel

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL

    // Platform limits and standards
    @State var textCount: Int = 0
    @State var hashtagCount: Int = 0
    @State var textLimit: Int = 0
    @State var hashtagLimit: Int = 0
    @State var isTextCopied: Bool = false

    // Extra settings
    @State var keyboardHeight: CGFloat = 0
    @State var shareableData: ShareableData?
    @State var isSelectingPlatform: Bool = false
    @State var selectedPlatform: String? = nil
    @State var isLoading: Bool = false
    @State var uiImage: UIImage? = nil

    // Used to determine if platform icons should display for Dropdown menu
    // Used to determine if CopyAndGo should be available - no if selected platform is General
    @State var shouldShowSocialMediaPlatform: Bool = false

    // Context
    var context: NavigationContext = .regular

    private func countHashtags(text: String) -> Int {
        let hashtagRegex = "#[a-zA-Z0-9_]+"
        do {
            let hashtagRegex = try NSRegularExpression(pattern: hashtagRegex)
            let matches = hashtagRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return matches.count
        } catch {
            print("Error creating regular expression")
            return 0
        }
    }

    private func convertSPToDropdownOptions() -> [DropdownOptions] {
        var options: [DropdownOptions] = []

        socialMediaPlatforms.forEach { sp in
            options.append(DropdownOptions(title: sp.title, imageName: sp.title == "General" ? "hashtag-white" : "\(sp.title)-circle", isCircularImage: sp.title != "General"))
        }

        return options
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: captionVm.selectedCaption.color).ignoresSafeArea(.all)

            GeometryReader { _ in
                VStack(alignment: .leading) {
                    // Header
                    HStack {
                        BackArrowView {
                            hideKeyboard()

                            // custom action
                            if context == .optimization {
                                self.navStack.pop(to: .previous)

                                self.captionVm.isCaptionSelected = true

                                // Update the selected caption with the edited text
                                self.captionVm.selectedCaption.captionDescription = self.captionVm.editedCaption.text
                            }

                            // once user navigates back, store edited caption into firebase
                            // as long as the editing was from the caption list context
                            // also only runs if there was a change in text
                            else if context == .captionList, captionVm.selectedCaption.captionDescription != captionVm.editedCaption.text {
                                self.isLoading = true
                                let userId = AuthManager.shared.userManager.user?.id ?? nil

                                captionVm.selectedCaption.captionDescription = captionVm.editedCaption.text
                                Task {
                                    await firestoreMan.updateSingleCaptionInFolder(for: userId, currentCaption: captionVm.selectedCaption) { updatedFolder in
                                        FolderViewModel.shared.updatedFolder = updatedFolder ?? nil

                                        // also update the search object with the most recent updated captions
                                        // for when a user wants to update the caption while searching
                                        self.searchVm.searchedCaptions = updatedFolder?.captions ?? []
                                        self.navStack.pop(to: .previous)
                                        self.isLoading = false
                                    }
                                }
                            } else {
                                // difference is that this pops outside of the asynchronous context
                                self.navStack.pop(to: .previous)
                            }

                            Heap.track("onClick EditCaptionView - Back button", withProperties: ["context": context, "caption": captionVm.editedCaption.text])
                        }
                        .disabled(isSelectingPlatform)
                        .padding(.leading, 8)

                        Spacer()

                        DropdownMenu(title: selectedPlatform == nil ? "General" : selectedPlatform!, socialMediaIcon: shouldShowSocialMediaPlatform ? selectedPlatform : nil, isMenuOpen: $isSelectingPlatform)
                            .overlay(alignment: .top) {
                                if isSelectingPlatform {
                                    VStack(alignment: .center) {
                                        Spacer(minLength: 50)
                                        DropdownMenuList(options: convertSPToDropdownOptions(), selectedOption: DropdownOptions(title: self.selectedPlatform ?? "")) { selectedPlatform in
                                            withAnimation {
                                                self.selectedPlatform = selectedPlatform
                                                self.isSelectingPlatform.toggle()
                                            }
                                        }
                                    }
                                }
                            }
                            // SwiftUI lets us stop a view from receiving any kind of taps using the allowsHitTesting() modifier. If hit testing is disallowed for a view, any taps automatically continue through the view on to whatever is behind it.
                            .allowsHitTesting(true)

                        Spacer()

                        CustomMenuPopup(menuTheme: .dark, orientation: .horizontal, shareableData: self.$shareableData, socialMediaPlatform: shouldShowSocialMediaPlatform ? $selectedPlatform : .constant(nil), copy: {
                            // Copy selected
                            self.isTextCopied = true
                            UIPasteboard.general.string = String(self.captionVm.editedCaption.text)
                            Heap.track("onClick EditCaptionView Custom Menu - Copy caption", withProperties: ["caption": captionVm.editedCaption.text])

                        }, reset: {
                            // Reset to original text
                            self.captionVm.editedCaption.text = self.captionVm.selectedCaption.captionDescription
                            Heap.track("onClick EditCaptionView Custom Menu - Reset caption", withProperties: ["caption": captionVm.editedCaption.text])
                        }, onMenuOpen: {
                            self.shareableData = mapShareableData(caption: captionVm.editedCaption.text, platform: shouldShowSocialMediaPlatform ? selectedPlatform : nil)
                        }, onCopyAndGo: {
                            // Copy and go run openSocialMediaLink(for: platform)
                            UIPasteboard.general.string = String(self.captionVm.editedCaption.text)
                            openSocialMediaLink(for: self.selectedPlatform ?? "")
                            Heap.track("onClick EditCaptionView Custom Menu - Copy & Go caption", withProperties: ["caption": captionVm.editedCaption.text])
                        })
                        .disabled(isSelectingPlatform)
                        .padding(.horizontal)
                    }
                    .zIndex(isSelectingPlatform ? 2 : 0)
                    .padding(.bottom, 20)

                    // Body
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            if let uiImage = uiImage {
                                ImageThumbnailView(uiImage: uiImage, showShadow: false) {
                                    // on thumbnail press, show full image
                                    withAnimation {
                                        photoSelectionVm.assignImageClickedFullscreen(uiImage: uiImage)
                                    }
                                }
                            }
                            
                            Text(captionVm.selectedCaption.title)
                                .foregroundColor(.ui.richBlack)
                                .font(.ui.title)
                                .frame(width: uiImage == nil ? SCREEN_WIDTH * 0.8 : SCREEN_WIDTH * 0.7, alignment: .leading)
                                .lineLimit(3)
                                .if(uiImage == nil) { view in
                                    return view
                                        .scaledToFit()
                                        .minimumScaleFactor(0.5)
                                }
                        }
                       

                        PlatformLimitsView(textCount: $textCount, hashtagCount: $hashtagCount, textLimit: textLimit, hashtagLimit: hashtagLimit)

                        CaptionTextEditorView(keyboardHeight: $keyboardHeight)
                            .padding(.horizontal, -2)
                    }
                    .padding(.horizontal, 15)
                    .disabled(isSelectingPlatform)
                }
                .padding()

                // Notification for when the user copies the caption
                FloatingNotificationView(title: "Copied and ready to paste! 👍")
                    .dropInAndOutAnimation(value: isTextCopied)
                    .offset(y: isTextCopied ? 30 : -SCREEN_HEIGHT)
            }
            .zIndex(isSelectingPlatform ? 1 : 0)
            .ignoresSafeArea(.keyboard, edges: .all)
            .blur(radius: self.isLoading ? 3 : 0)

            if isSelectingPlatform {
                Color.ui.richBlack.opacity(0.35).ignoresSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            self.isSelectingPlatform.toggle()
                        }
                    }
            }

            // Calls activity indicator here
            if self.isLoading {
                SimpleLoadingView(scaledSize: 3, title: "Saving...")
            }
        }
        .disabled(self.isLoading)
        .onDisappear {
            if context != .optimization {
                captionVm.resetSelectedCaption()
                captionVm.resetEditedCaption()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    self.captionVm.editedCaption.text.append("#")
                    Haptics.shared.play(.soft)
                } label: {
                    Image("\(colorScheme == .dark ? "hashtag-white" : "hashtag-black")")
                        .resizable()
                        .frame(width: 20, height: 20, alignment: .leading)
                }
                .frame(width: 100, alignment: .leading)

                Spacer()

                if let selectedPlatform = self.selectedPlatform, shouldShowSocialMediaPlatform {
                    CaptionCopyBtnView(platform: selectedPlatform) {
                        // On copy
                        self.isTextCopied = true
                        UIPasteboard.general.string = String(self.captionVm.editedCaption.text)
                        Haptics.shared.play(.soft)
                    } onPlatformClick: {
                        // On platform
                        openSocialMediaLink(for: selectedPlatform)
                        Haptics.shared.play(.soft)
                    }
                }

                VerticalDivider(color: Color.primary)
                    .padding(.horizontal, 10)

                ZStack(alignment: .trailing) {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)

                    Rectangle()
                        .frame(width: 30, height: 20)
                        .opacity(0.001)
                        .onTapGesture {
                            hideKeyboard()
                            Haptics.shared.play(.soft)
                        }
                }
            }
        }
        .onAppear {
            self.textCount = self.captionVm.selectedCaption.captionDescription.count
            self.hashtagCount = self.countHashtags(text: self.captionVm.selectedCaption.captionDescription)

            // Resets the flag to dismiss notification after 3 seconds
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                if self.isTextCopied {
                    self.isTextCopied = false
                }
            }

            // find specific folder for a caption if editing from the caption list
            if context == .captionList, let user = AuthManager.shared.userManager.user {
                // filter to a folder for a specific caption
                // BUG: -- If user updates the folder within FolderView(), this won't work as the folderId will change. Must choose updated folder Id
                if let folder = user.folders.first(where: { $0.id == captionVm.selectedCaption.folderId }) {
                    // Update platform based on folder type
                    self.selectedPlatform = folder.folderType.rawValue

                    // Set text to be edited
                    captionVm.editedCaption.text = captionVm.selectedCaption.captionDescription
                    
                    // retrieve image if any
                    let imagePath = "saved_images/users/\(user.id)/folders/\(folder.id)/caption_images/\(captionVm.selectedCaption.id).jpg"
                    firestoreMan.retrieveImage(imagePath: imagePath) { result in
                        switch result {
                        case .success(let image):
                            self.uiImage = image
                        case .failure:
                            break;
                        }
                    }
                }
            }

            Heap.track("onAppear EditCaptionView", withProperties: ["context": context, "caption": captionVm.selectedCaption.captionDescription, "type": selectedPlatform == nil ? "General" : selectedPlatform!])
        }
        .onChange(of: self.selectedPlatform, perform: { sp in
            if let sp = sp {
                // Update text and hashtag limits based on selected platform
                let socialMediaFiltered = socialMediaPlatforms.first(where: { $0.title == sp })
                self.textLimit = socialMediaFiltered?.characterLimit ?? 0
                self.hashtagLimit = socialMediaFiltered?.hashtagLimit ?? 0

                self.shouldShowSocialMediaPlatform = !sp.isEmpty && sp != "General"
            }

        })
        .onChange(of: captionVm.editedCaption.text) { value in
            // Count number of chars in the text
            self.textCount = value.count

            // Count the amount of hashtags used in the text
            self.hashtagCount = self.countHashtags(text: value)
        }
        .onReceive(Publishers.keyboardHeight) { keyboardHeight in
            withAnimation(.spring()) {
                self.keyboardHeight = keyboardHeight
            }
        }
        // show full image on click
        .overlay(
            FullScreenImageOverlay(isFullScreenImage: $photoSelectionVm.showImageInFullScreen, image: photoSelectionVm.fullscreenImageClicked, imageHeight: .constant(nil))
        )
    }
}

struct EditCaptionView_Previews: PreviewProvider {
    static var previews: some View {
        EditCaptionView()
            .environmentObject(NavigationStackCompat())
            .environmentObject(OpenAIConnector())
            .environmentObject(CaptionViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(FolderViewModel())

        EditCaptionView()
            .environmentObject(NavigationStackCompat())
            .environmentObject(OpenAIConnector())
            .environmentObject(CaptionViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(FolderViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct PlatformLimitsView: View {
    @Binding var textCount: Int
    @Binding var hashtagCount: Int
    let textLimit: Int
    let hashtagLimit: Int

    private func renderTextColor() -> Color {
        if textLimit > 0 && textCount >= textLimit {
            return Color.ui.dangerRed
        }

        return Color.ui.richBlack
    }

    private func renderHashtagColor() -> Color {
        if hashtagLimit > 0 && hashtagCount >= hashtagLimit {
            return Color.ui.dangerRed
        }

        return Color.ui.richBlack
    }

    var body: some View {
        HStack {
            Text("\(textCount)")
                .foregroundColor(renderTextColor())
                .font(.ui.headlineMediumSm)
                +
                Text("\(textLimit > 0 ? "/\(textLimit)" : "") text")
                .foregroundColor(renderTextColor())
                .font(.ui.headlineLightSm)

            VerticalDivider()

            Text("\(hashtagCount)")
                .foregroundColor(renderHashtagColor())
                .font(.ui.headlineMediumSm)
                +

                Text("\(hashtagLimit > 0 ? "/\(hashtagLimit)" : "") hashtags")
                .foregroundColor(renderHashtagColor())
                .font(.ui.headlineLightSm)
        }
    }
}

struct CaptionTextEditorView: View {
    @EnvironmentObject var captionVm: CaptionViewModel
    @Binding var keyboardHeight: CGFloat

    var body: some View {
        TextEditor(text: $captionVm.editedCaption.text)
            .font(.ui.graphikRegular)
            .foregroundColor(Color.ui.richBlack)
            .lineSpacing(6)
            .scrollContentBackground(.hidden)
            .frame(height: SCREEN_HEIGHT * 0.6 - (keyboardHeight > 0 ? abs(keyboardHeight - 100) : 0))
    }
}

struct CaptionCopyBtnView: View {
    @State var isClicked: Bool = false
    let platform: String
    var onCopy: () -> Void
    var onPlatformClick: () -> Void

    var body: some View {
        Button {
            self.isClicked.toggle()
            if self.isClicked {
                onCopy()
            } else {
                onPlatformClick()
            }
        } label: {
            HStack {
                if isClicked {
                    Image(platform)
                        .resizable()
                        .frame(width: 25, height: 25)
                } else {
                    CopyIconView()
                        .padding(.trailing, 5)
                }

                Text("\(isClicked ? "Open \(platform)" : "Copy")")
                    .foregroundColor(Color.primary)
                    .font(.ui.headline)
            }
        }
    }
}

struct VerticalDivider: View {
    let height: CGFloat = 20
    @State var color: Color = Color.ui.richBlack

    var body: some View {
        Rectangle()
            .fill(color)
            .opacity(0.3)
            .frame(width: 1, height: height)
    }
}

struct CopyIconView: View {
    let size: CGFloat = 17

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary, lineWidth: 3)
                .frame(width: size, height: size)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary)
                .offset(x: 5, y: -5)
                .frame(width: size, height: size)
        }
    }
}
