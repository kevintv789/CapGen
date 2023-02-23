//
//  FolderBottomSheetView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/22/23.
//  Used for creation and editing a folder

import SwiftUI

struct FolderBottomSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var firestoreMan: FirestoreManager
    
    @State var title: String = "Create your folder"
    var isEditing: Bool

    @State var folderName: String = ""
    @State var selectedPlatform: FolderType = .General // default selected
    @State var isLoading: Bool = false
    @State var isFolderNameError: Bool = false
    
    private func onSubmit() {
        self.isFolderNameError = false
        
        if folderName.isEmpty {
            self.isFolderNameError = true
            return
        }
        
        self.isLoading = true
        
        // Call API to update firebase
        let userId = AuthManager.shared.userManager.user?.id ?? nil
        
        let newFolder = FolderModel(name: folderName, folderType: selectedPlatform, captions: [])

        firestoreMan.saveFolder(for: userId, folder: newFolder) {
            self.isLoading = false
            dismiss()
        }
    }

    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea()

            ScrollView {
                VStack {
                    Text(title)
                        .font(.ui.largeTitleSm)
                        .foregroundColor(.ui.richBlack)
                        .padding(.bottom, 40)

                    // Folder name input
                    FolderNameInput(folderName: $folderName, isError: $isFolderNameError)
                        .padding(.bottom, 20)

                    // Choose a platform 3x3 grid
                    PlatformGridView(selectedPlatform: $selectedPlatform)
                    
                    // Submit button
                    PrimaryButtonView(title: "Create", isLoading: $isLoading) {
                        // Run API to create the specified folder
                        onSubmit()
                    }
                    .frame(width: SCREEN_WIDTH * 0.8, height: 55)
                    .padding(.top)

                    Spacer()
                }
                .padding()
            }
           
        }
        .onAppear {
            // Update data based on user action
            if isEditing {
                self.title = "Edit folder"
            }
        }
    }
}

struct FolderNameInput: View {
    @Binding var folderName: String
    @Binding var isError: Bool

    var body: some View {
        VStack {
            Text("Folder name (required)")
                .foregroundColor(isError ? .ui.dangerRed : .ui.cadetBlueCrayola)
                .font(.ui.headline)

            RoundedRectangle(cornerRadius: 14)
                .fill(isError ? .ui.dangerRed.opacity(0.3) : Color.ui.lighterLavBlue)
                .opacity(0.4)
                .frame(width: SCREEN_WIDTH * 0.8, height: 51)
                .overlay(
                    HStack(spacing: 0) {
                        TextField("", text: $folderName)
                            .padding()
                            .placeholder(when: folderName.isEmpty) {
                                Text("Enter a folder name")
                                    .font(.ui.headlineMd)
                                    .foregroundColor(.ui.cadetBlueCrayola)
                                    .padding()
                            }
                            .foregroundColor(.ui.richBlack)

                        if !folderName.isEmpty {
                            Button {
                                Haptics.shared.play(.soft)
                                folderName.removeAll()
                            } label: {
                                Image(systemName: "x.circle.fill")
                                    .font(.ui.headline)
                                    .foregroundColor(.ui.cadetBlueCrayola)
                            }
                            .padding(.trailing)
                        }

                        
                    }
                )
              
        }
    }
}

struct PlatformGridView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    @Binding var selectedPlatform: FolderType
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack {
            Text("Choose a platform")
                .foregroundColor(.ui.cadetBlueCrayola)
                .font(.ui.headline)
                .padding(.bottom)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(socialMediaPlatforms) { platform in
                    Button {
                        self.selectedPlatform = FolderType(rawValue: platform.title)!
                    } label: {
                        VStack(spacing: 10) {
                            Image("\(platform.title)-circle")
                                .resizable()
                                .frame(width: 35 * scaledSize, height: 35 * scaledSize)
                                .background(
                                    ZStack(alignment: .topTrailing) {
                                        if (self.selectedPlatform == FolderType(rawValue: platform.title)!) {
                                            Circle()
                                                .strokeBorder(Color.ui.middleBluePurple, lineWidth: 3)
                                                
                                            Circle()
                                                .fill(Color.ui.middleBluePurple)
                                                .overlay(
                                                    Image("checkmark-white")
                                                        .resizable()
                                                        .foregroundColor(.ui.cultured)
                                                        .frame(width: 10 * scaledSize, height: 10 * scaledSize)
                                                )
                                                .frame(width: 22 * scaledSize, height: 22 * scaledSize)
                                        }
                                    }
                                        .frame(width: 65 * scaledSize, height: 65 * scaledSize)
                                )
                                .padding(10)
                            
                            Text(platform.title)
                                .foregroundColor(self.selectedPlatform == FolderType(rawValue: platform.title)! ? .ui.middleBluePurple : .ui.lighterLavBlue)
                                .font(.ui.headline)
                        }
                    }
                    
                }
            }
            
           
        }
    }
}
