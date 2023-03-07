//
//  EditCaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/25/23.
//

import Combine
import NavigationStack
import SwiftUI
import UIKit

enum EditCaptionContext {
    case optimization, regular
}

struct EditCaptionView: View {
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var captionEditVm: CaptionEditViewModel
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionVm: CaptionViewModel

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL

    // Requirements
    let bgColor: Color
    let captionTitle: String
    let platform: String
    let caption: String

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

    // Used to determine if platform icons should display for Dropdown menu
    // Used to determine if CopyAndGo should be available - no if selected platform is General
    @State var shouldShowSocialMediaPlatform: Bool = false

    // Context
    var context: EditCaptionContext = .regular

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

    private func generateShareableData() -> ShareableData {
        var item: String {
            """
            Behold the precious caption I generated from ⚡CapGen⚡\(shouldShowSocialMediaPlatform ? " for my \(selectedPlatform ?? "")" : "")!

            "\(captionEditVm.editableText)"
            """
        }

        let newShareableData = ShareableData(item: item, subject: "Check out my caption from CapGen!")
        return newShareableData
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            bgColor.ignoresSafeArea(.all)

            GeometryReader { _ in
                VStack(alignment: .leading) {
                    // Header
                    HStack {
                        BackArrowView {
                            // custom action
                            if context == .optimization {
                                self.captionVm.isCaptionSelected = true
                            }

                            self.navStack.pop(to: .previous)
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
                            UIPasteboard.general.string = String(self.captionEditVm.editableText)

                        }, reset: {
                            // Reset to original text
                            self.captionEditVm.editableText = self.caption
                        }, onMenuOpen: {
                            self.shareableData = generateShareableData()
                        }, onCopyAndGo: {
                            // Copy and go run openSocialMediaLink(for: platform)
                            UIPasteboard.general.string = String(self.captionEditVm.editableText)
                            openSocialMediaLink(for: self.selectedPlatform ?? "")
                        })
                        .disabled(isSelectingPlatform)
                        .padding(.horizontal)
                    }
                    .zIndex(isSelectingPlatform ? 2 : 0)
                    .padding(.bottom, 20)

                    // Body
                    VStack(alignment: .leading, spacing: 15) {
                        Text(captionTitle)
                            .foregroundColor(.ui.richBlack)
                            .font(.ui.title)
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                            .frame(width: SCREEN_WIDTH * 0.8, alignment: .leading)
                            .lineLimit(2)

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

            if isSelectingPlatform {
                Color.ui.richBlack.opacity(0.35).ignoresSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            self.isSelectingPlatform.toggle()
                        }
                    }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    self.captionEditVm.editableText.append("#")
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
                        UIPasteboard.general.string = String(self.captionEditVm.editableText)
                        Haptics.shared.play(.soft)
                    } onPlatformClick: {
                        // On platform
                        openSocialMediaLink(for: selectedPlatform)
                        Haptics.shared.play(.soft)
                    }
                }

                VerticalDivider(color: Color.primary)
                    .padding(.horizontal, 10)

                Button {
                    hideKeyboard()
                    Haptics.shared.play(.soft)
                } label: {
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.primary)
                        .frame(width: 20, height: 20, alignment: .trailing)
                }
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, -12)
                .padding(.leading, -5)
            }
        }
        .onAppear {
            self.captionEditVm.editableText = self.caption
            self.textCount = self.caption.count
            self.hashtagCount = self.countHashtags(text: self.caption)

            // Resets the flag to dismiss notification
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                if self.isTextCopied {
                    self.isTextCopied = false
                }
            }
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
        .onChange(of: captionEditVm.editableText) { value in
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
    }
}

struct EditCaptionView_Previews: PreviewProvider {
    static var previews: some View {
        EditCaptionView(bgColor: Color.ui.middleYellowRed, captionTitle: "Rescued Love Unleashed", platform: "", caption: "Life is so much better with a furry friend to share it with! My rescue pup brings me #so much joy and love every day. 🤗")
            .environmentObject(CaptionEditViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(OpenAIConnector())
            .environmentObject(CaptionViewModel())

        EditCaptionView(bgColor: Color.ui.middleYellowRed, captionTitle: "Rescued Love Unleashed", platform: "LinkedIn", caption: "🐶💕 Life is so much better with a furry friend to share it with! My rescue pup brings me so much joy and love every day. 🤗")
            .environmentObject(CaptionEditViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(OpenAIConnector())
            .environmentObject(CaptionViewModel())
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
    @EnvironmentObject var captionEditVm: CaptionEditViewModel
    @Binding var keyboardHeight: CGFloat

    var body: some View {
        TextEditor(text: $captionEditVm.editableText)
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
