//
//  HomeView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/11/23.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @State var credits: Int = AuthManager.shared.userManager.user?.credits ?? 0
    
    @FocusState private var isKeyboardFocused: Bool
    @State var expandBottomArea: Bool = false
    
    @State var platformSelected: String
    @State var promptText: String = ""
    @State var showRefillModal: Bool = false
    @State var showCongratsModal: Bool = false
    @State var isAdLoading: Bool = false
    
    @FocusState private var isFocused: Bool
    
    init(promptText: String, platformSelected: String) {
        self.promptText = promptText
        self.platformSelected = platformSelected
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ui.cultured.ignoresSafeArea()
                Color.ui.lighterLavBlue.ignoresSafeArea()
                    .opacity(0.5)
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                    VStack {
                        HStack(alignment: .center) {
                            Text("Which platform is this for?")
                                .padding(.leading, 16)
                                .font(.ui.headline)
                                .foregroundColor(Color.ui.richBlack)
                            
                            Spacer()
                            
                            CreditCounterView(credits: $credits, showModal: $showRefillModal)
                                .padding(.trailing, 16)
                        }
                      
                        ScrollViewReader { scrollProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(alignment: .top, spacing: 15) {
                                    ForEach(socialMediaPlatforms) { platform in
                                        Button {
                                            withAnimation(.spring()) {
                                                self.platformSelected = platform.title
                                            }
                                            
                                        } label: {
                                            Pill(title: platform.title, isToggled: platform.title == self.platformSelected)
                                        }
                                    }
                                }
                                .onTapGesture {
                                    hideKeyboard()
                                }
                                .padding()
                            }
                            .frame(height: 75)
                            .onChange(of: self.platformSelected) { value in
                                withAnimation {
                                    scrollProxy.scrollTo(self.platformSelected, anchor: .center)
                                }
                            }
                        }
                        
                        // Create a Text Area view that is the main component for typing input
                        TextAreaView(text: $promptText)
                            .frame(width: SCREEN_WIDTH / 1.1, height: SCREEN_HEIGHT / 2)
                            .position(x: SCREEN_WIDTH / 2, y: SCREEN_HEIGHT / 4)
                            .focused($isFocused)
                        
                        BottomAreaView(expandArea: $expandBottomArea, platformSelected: $platformSelected, promptText: $promptText, credits: $credits, isAdLoading: $isAdLoading)
                            .frame(maxHeight: SCREEN_HEIGHT)
                    }
                .scrollDismissesKeyboard(.interactively)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .onReceive(AuthManager.shared.userManager.$user) { user in
                if user != nil {
                    self.credits = user!.credits
                }
            }
            .modalView(horizontalPadding: 40, show: $showRefillModal) {
                RefillModalView(isViewPresented: $showRefillModal, showCongratsModal: $showCongratsModal)
            } onClickExit: {
                withAnimation {
                    self.showRefillModal = false
                }
            }
            .modalView(horizontalPadding: 40, show: $showCongratsModal) {
                CongratsModalView(showView: $showCongratsModal)
            } onClickExit: {
                withAnimation {
                    self.showCongratsModal = false
                }
            }
            .modalView(horizontalPadding: 80, show: $isAdLoading, content: {
                OverlayedLoaderView()
            }, onClickExit: nil)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(promptText: "", platformSelected: socialMediaPlatforms[0].title)
            .environmentObject(TaglistViewModel())
        
        HomeView(promptText: "", platformSelected: socialMediaPlatforms[0].title)
            .environmentObject(TaglistViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
