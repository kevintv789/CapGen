//
//  FolderView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/21/23.
//

import SwiftUI

struct FolderView: View {
    @State var showCreateFolderBottomSheet: Bool = false
    @State var folders: [FolderModel] = []

    let columns = [
        GridItem(.flexible(minimum: 10), spacing: 0),
        GridItem(.flexible(minimum: 10), spacing: 0),
        GridItem(.flexible(minimum: 10), spacing: 0),
    ]
    
    var isExpanded: Bool
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(Array(folders.enumerated()), id: \.element) { index, data in
                    if index == 0 {
                        AddFolderButtonView {
                            Haptics.shared.play(.soft)
                            
                            // show bottom sheet
                            self.showCreateFolderBottomSheet = true
                        }
                        .padding(.top, 20)
                    }
                    
                    HStack(spacing: 0) {
                        FolderButtonView(folder: data)
                        
                        CustomMenuPopup(menuTheme: .dark, orientation: .vertical, shareableData: .constant(nil), size: .medium, opacity: 0.25)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.leading, -33)
                            .padding(.top)
                    }
                    
                }
                .padding(.bottom, -10)
            }
        }
        .sheet(isPresented: $showCreateFolderBottomSheet) {
            FolderBottomSheetView(isEditing: false)
                .presentationDetents([.fraction(0.8)])
        }
        .onReceive(AuthManager.shared.userManager.$user) { user in
            if let user = user {
                self.folders = user.folders
            }
        }
    }
}

struct AddFolderButtonView: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 30) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.ui.cultured)
                    .background(
                        Circle()
                            .fill(Color.ui.lighterLavBlue)
                            .frame(width: 60, height: 60)
                            .shadow(color: .ui.richBlack.opacity(0.35), radius: 3, x: 1, y: 2)
                    )

                Text("Create folder")
                    .foregroundColor(.ui.richBlack).opacity(0.5)
                    .font(.ui.headlineMd)
            }
        }
    }
}

struct FolderButtonView: View {
    let folder: FolderModel
    
    var body: some View {
        Button {
            
        } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    Image("main_folder")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .overlay(
                            ZStack(alignment: .topLeading) {
                                // Renders the social media platform image
                                HStack {
                                    if folder.folderType != .General {
                                        Image("\(folder.folderType.rawValue)-circle")
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .background(
                                                Circle()
                                                    .fill(Color.ui.cultured)
                                                    .frame(width: 35, height: 35)
                                                    
                                            )
                                            .padding(30)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .padding(.top, 5)
                                    }
                                    
                                        
                                }
                               
                            }
                        )
                    
                
                    
                    Text("\(folder.captions.count)")
                        .padding(30)
                        .padding(.trailing, -5)
                        .font(.ui.headlineMd)
                        .foregroundColor(.ui.richBlack.opacity(0.5))
                    
                }
                
                Text(folder.name)
                    .font(.ui.headlineMd)
                    .foregroundColor(.ui.richBlack).opacity(0.5)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.top, -15)
                
                
                Spacer()
            }
           
           
        }
       
    }
}
