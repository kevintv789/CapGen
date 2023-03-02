//
//  CaptionOptimizationBottomSheetView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/28/23.
//

import SwiftUI

struct CaptionOptimizationBottomSheetView: View {
    @EnvironmentObject var captionVm: CaptionViewModel

    // Private variables
    @State var selectedIndex: Int = 0
    @State var offset: CGFloat = 0

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
            
            if self.selectedIndex == 0 {
                self.offset = 0
            } else {
                self.offset = -SCREEN_WIDTH
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

                    SelectedCaptionCardButton(caption: captionVm.selectedCaption.description, colorFilled: $captionVm.selectedCaption.color)
                        {
                            // on click, take user to edit caption screen
                        }
                        .frame(maxHeight: 250)
                        .padding(.horizontal, 25)

                    
                    TopTabView(selectedIndex: $selectedIndex, offset: $offset)
                        .padding(.top)

                    GeometryReader { geo in
                        HStack(alignment: .center, spacing: 0) {
                            SaveToFolderView()
                                .frame(width: geo.frame(in: .global).width)

                            CopyAndGoView()
                                .frame(width: geo.frame(in: .global).width)
                        }
                        .offset(x: self.offset)
                        .frame(minHeight: geo.size.height * 0.3,
                                   maxHeight: geo.size.height * 0.3)
                        
                    }
                    
                    Spacer()
                   
                }
            }
            // Create drag gesture to rotate between views
            .highPriorityGesture(
                DragGesture()
                    .onEnded({ value in
                        if value.translation.width > 50 {
                            // drag rightat a minimum of 50
                            self.changeView(left: false)
                        }
                        
                        if -value.translation.width > 50 {
                            // drag left at a minimum of 50
                            self.changeView(left: true)
                        }
                    })
            )
            .padding(.top)
        }
    }
}

struct SelectedCaptionCardButton: View {
    var caption: String
    @Binding var colorFilled: Color

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
                    .fill(colorFilled)

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
    @Binding var offset: CGFloat

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Button {
                    withAnimation {
                        self.selectedIndex = 0
                        self.offset = 0
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
                        self.offset = -SCREEN_WIDTH
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
    var body: some View {
        VStack {
            Text("Click on each folder you want to save your caption to.")
                .foregroundColor(.ui.richBlack.opacity(0.5))
                .font(.ui.subheadlineLarge)
                .lineSpacing(5)
                .frame(height: 50)
            
            FolderGridView()
            
            Spacer()
        }
//        .padding(.horizontal)
//        .frame(height: SCREEN_HEIGHT)
    }
}

struct CopyAndGoView: View {
    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                Text("Copy your caption and launch the social media app with a single tap.")
                    .foregroundColor(.ui.richBlack.opacity(0.5))
                    .font(.ui.subheadlineLarge)
                    .lineSpacing(5)
                    .frame(width: SCREEN_WIDTH * 0.9)
                    .padding(.bottom)
                
                SocialMediaGridView()
                
                Spacer()
            }
            .padding(.horizontal)
//        }
      
//        .frame(height: SCREEN_HEIGHT)
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
