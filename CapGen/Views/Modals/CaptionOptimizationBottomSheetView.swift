//
//  CaptionOptimizationBottomSheetView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/28/23.
//

import NavigationStack
import SwiftUI
import Heap

struct CaptionOptimizationBottomSheetView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var captionVm: CaptionViewModel
    @EnvironmentObject var folderVm: FolderViewModel
    @EnvironmentObject var navStack: NavigationStackCompat

    // Private variables
    @State var selectedIndex: Int = 0
    @State var isSavingToFolder: Bool = false
    @State var isSuccessfullySaved: Bool = false

    // Used in dragGesture to rotate tab between views
    private func changeView(left: Bool) {
        withAnimation {
            if left {
                if self.selectedIndex != 1 {
                    self.selectedIndex += 1
                }
            } else {
                if self.selectedIndex != 0 {
                    self.selectedIndex -= 1
                }
            }
        }
    }

    private func saveCaptionsToFolder() {
        isSavingToFolder = true

        let captionsToSaveWithFolderId = folderVm.captionFolderStorage

        if let user = AuthManager.shared.userManager.user {
            let userId = user.id

            firestoreMan.saveCaptionsToFolders(for: userId, destinationFolders: captionsToSaveWithFolderId) {
                // get current folders
                let currentFolders = user.folders
                if !currentFolders.isEmpty {
                    withAnimation {
                        folderVm.resetFolderStorage()
                        self.isSavingToFolder = false
                        self.isSuccessfullySaved = true

                        // Resets Saved! tag after 1 second
                        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                            self.isSuccessfullySaved = false
                        }
                        
                        Heap.track("onClick CaptionOptimizationBottomSheet - Apply button clicked, save caption to folder success", withProperties: [ "folders": captionsToSaveWithFolderId, "caption": captionVm.selectedCaption.captionDescription ])
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 25) {
                    Text("How do you want to use this caption?")
                        .font(.ui.headline)
                        .foregroundColor(.ui.richBlack)
                        .padding(.top)

                    SelectedCaptionCardButton(caption: captionVm.selectedCaption.captionDescription, colorFilled: $captionVm.selectedCaption.color)
                        {
                            // on click, take user to edit caption screen
                            self.navStack.push(EditCaptionView(context: .optimization))
                            
                            Heap.track("onClick CaptionOptimizationBottomSheet - Caption card clicked, pushing to Edit screen", withProperties: [ "caption": captionVm.selectedCaption.captionDescription ])
                        }
                        .frame(maxHeight: 250)
                        .padding(.horizontal, 25)

                    TopTabView(selectedIndex: $selectedIndex)
                        .padding(.top)

                    if self.selectedIndex == 0 {
                        SaveToFolderView(isLoading: $isSavingToFolder, isSaved: $isSuccessfullySaved, onApplyClick: {
                            // Save all captions from temp storage to firebase
                            self.saveCaptionsToFolder()
                        })
                        .frame(width: SCREEN_WIDTH * 0.9)
                        .frame(minHeight: SCREEN_HEIGHT / 2)
                    } else {
                        CopyAndGoView()
                            .frame(width: SCREEN_WIDTH * 0.95)
                    }
                }

                Spacer()
            }
            .onDisappear {
                folderVm.resetFolderStorage()
                self.isSavingToFolder = false
                self.isSuccessfullySaved = true
                
                Heap.track("onDisappear CaptionOptimizationBottomSheet")
            }
            // Create drag gesture to rotate between views
            .highPriorityGesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 50 {
                            // drag rightat a minimum of 50
                            self.changeView(left: false)
                        }

                        if -value.translation.width > 50 {
                            // drag left at a minimum of 50
                            self.changeView(left: true)
                        }
                    }
            )
            .padding(.top)
        }
        .onAppear() {
            Heap.track("onAppear CaptionOptimizationBottomSheet", withProperties: [ "caption": captionVm.selectedCaption.captionDescription ])
        }
    }
}

struct SelectedCaptionCardButton: View {
    var caption: String
    @Binding var colorFilled: String

    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.ui.cultured, lineWidth: 10)
                    .shadow(color: .ui.richBlack.opacity(0.4), radius: 4, x: 0, y: 2)

                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: colorFilled))

                ScrollView {
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack {
                            Text(caption.trimmingCharacters(in: .whitespaces))
                                .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 15))
                                .font(.ui.graphikRegular)
                                .lineSpacing(4)
                                .foregroundColor(.ui.richBlack)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

struct TopTabView: View {
    @Binding var selectedIndex: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Button {
                    withAnimation {
                        self.selectedIndex = 0
                    }

                } label: {
                    Text("Save to folder")
                        .font(self.selectedIndex == 0 ? .ui.title4 : .ui.title4Medium)
                        .foregroundColor(self.selectedIndex == 0 ? .ui.middleBluePurple : .ui.cadetBlueCrayola)
                }

                Capsule()
                    .fill(Color.ui.darkerPurple)
                    .frame(width: 50, height: 4)
                    .opacity(self.selectedIndex == 0 ? 1 : 0)
            }

            Spacer()
                .frame(width: 80)

            VStack(alignment: .leading) {
                Button {
                    withAnimation {
                        self.selectedIndex = 1
                    }

                } label: {
                    Text("Copy & Go")
                        .font(self.selectedIndex == 1 ? .ui.title4 : .ui.title4Medium)
                        .foregroundColor(self.selectedIndex == 1 ? .ui.middleBluePurple : .ui.cadetBlueCrayola)
                }

                Capsule()
                    .fill(Color.ui.darkerPurple)
                    .frame(width: 50, height: 4)
                    .opacity(self.selectedIndex == 1 ? 1 : 0)
            }
        }
    }
}

struct SaveToFolderView: View {
    @EnvironmentObject var folderVm: FolderViewModel

    @Binding var isLoading: Bool
    @Binding var isSaved: Bool
    var onApplyClick: () -> Void

    var body: some View {
        VStack {
            Text("Tap on each folder you want to save your caption to.")
                .foregroundColor(.ui.richBlack.opacity(0.5))
                .font(.ui.subheadlineLarge)
                .lineSpacing(5)
                .frame(height: 50)

            if !folderVm.captionFolderStorage.isEmpty {
                ApplyButtonView(isLoading: $isLoading, onApplyClick: onApplyClick)
            } else if folderVm.captionFolderStorage.isEmpty && !isLoading && isSaved {
                SavedTagView()
            }

            FolderGridView(context: .saveToFolder, disableTap: $isLoading)

            Spacer()
        }
    }
}

struct CopyAndGoView: View {
    var body: some View {
        VStack {
            Text("Copy your caption and launch the social media app with a single tap.")
                .foregroundColor(.ui.richBlack.opacity(0.5))
                .font(.ui.subheadlineLarge)
                .lineSpacing(5)
                .padding(.bottom)

            SocialMediaGridView()

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct SocialMediaGridView: View {
    @EnvironmentObject var captionVm: CaptionViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(socialMediaPlatforms) { sp in
                if sp.title != "General" {
                    Button {
                        UIPasteboard.general.string = String(captionVm.selectedCaption.captionDescription)
                        openSocialMediaLink(for: sp.title)
                        Haptics.shared.play(.soft)
                        
                        Heap.track("onClick CaptionOptimizationBottomSheet - Copy & Go clicked", withProperties: [ "social_media_platform": sp.title, "caption": captionVm.selectedCaption.captionDescription ])
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.ui.cultured)
                                .shadow(color: .ui.richBlack.opacity(0.5), radius: 4, x: 0, y: 2)

                            Image("\(sp.title)-circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                        .frame(width: 65, height: 65)
                    }
                }
            }
        }
    }
}

struct ApplyButtonView: View {
    @Binding var isLoading: Bool
    var onApplyClick: () -> Void

    var body: some View {
        Button {
            Haptics.shared.play(.soft)
            onApplyClick()
            
        } label: {
            Text("\(isLoading ? "" : "Apply")")
                .font(.ui.headline)
                .foregroundColor(.ui.cadetBlueCrayola)
                .padding(.horizontal, 25)
                .padding(.vertical, 5)
                .background(
                    ZStack {
                        if !isLoading {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.ui.cadetBlueCrayola, lineWidth: 3)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.ui.cultured, lineWidth: 3)
                                .shadow(color: Color.ui.richBlack.opacity(0.5), radius: 3, x: 0, y: 2)

                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.ui.darkerPurple)
                        }
                    }
                )
                .if(isLoading) { button in
                    button.overlay(
                        LottieView(name: "btn_loader", loopMode: .loop, isAnimating: true)
                            .frame(width: 50, height: 50)
                    )
                }
        }
        .disabled(isLoading)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 20)
    }
}

struct SavedTagView: View {
    var body: some View {
        HStack {
            Image("checkmark_success_circle")
                .resizable()
                .frame(width: 17, height: 17)

            Text("Saved!")
                .font(.ui.headline)
                .foregroundColor(.ui.cultured)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 5)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.ui.cultured, lineWidth: 4)
                    .shadow(color: .ui.richBlack.opacity(0.4), radius: 2, x: 0, y: 2)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ui.green)
            }
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 20)
    }
}
