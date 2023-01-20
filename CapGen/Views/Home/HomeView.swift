//
//  HomeView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/11/23.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    let socialMediaPlatforms = SocialMediaPlatforms()
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
    
    func platformSelect(platform: String) {
        platformSelected = platform
    }
    
    func getWidthDivisorForCreditCounter() -> CGFloat {
        if (credits < 10) {
            return 2.5
        } else if (credits > 10) {
            return 2.3
        }
        
        return 2.1
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
                
                GeometryReader { geo in
                    VStack(alignment: .trailing) {
                        CreditCounterView(credits: $credits, showModal: $showRefillModal)
                            .frame(width: geo.size.width / getWidthDivisorForCreditCounter(), height: 35)
                            .padding(.trailing, 15)
                        
                        Text("Which social media platform is this for?")
                            .padding(.leading, 16)
                            .padding(.top, 6)
                            .font(.ui.graphikSemibold)
                            .foregroundColor(Color.ui.richBlack)
                            .frame(width: geo.size.width, alignment: .center)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(alignment: .top, spacing: 16) {
                                ForEach(socialMediaPlatforms.platforms, id: \.self) { platform in
                                    Button {
                                        platformSelect(platform: platform)
                                    } label: {
                                        Pill(title: platform, isToggled: platform == platformSelected)
                                    }
                                }
                            }
                            .onTapGesture {
                                hideKeyboard()
                            }
                            .padding()
                        }
                        .frame(height: 75)
                        // Create a Text Area view that is the main component for typing input
                        TextAreaView(text: $promptText)
                            .frame(width: geo.size.width / 1.1, height: geo.size.height / 1.7)
                            .position(x: geo.size.width / 2, y: geo.size.height / 3.5)
                            .focused($isFocused)
                        
                        BottomAreaView(expandArea: $expandBottomArea, platformSelected: $platformSelected, promptText: $promptText, credits: $credits, isAdLoading: $isAdLoading)
                            .frame(maxHeight: geo.size.height)
                    }
                    
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
        HomeView(promptText: "", platformSelected: SocialMediaPlatforms.init().platforms[0])
        
        HomeView(promptText: "", platformSelected: SocialMediaPlatforms.init().platforms[0])
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
