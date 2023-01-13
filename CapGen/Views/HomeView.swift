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
    let envName: String = Bundle.main.infoDictionary?["ENV"] as! String
    @EnvironmentObject var googleAuthMan: GoogleAuthManager
    
    @FocusState private var isKeyboardFocused: Bool
    @State var expandBottomArea: Bool = false
    
    @State var platformSelected: String
    @State var promptText: String = ""
    
    @FocusState private var isFocused: Bool
    
    func platformSelect(platform: String) {
        platformSelected = platform
    }
    
    func logout() {
        DispatchQueue.global(qos: .background).async {
            if (googleAuthMan.googleSignInState == .signedIn) {
                // We know Google SSO was used, sign out using Google
                // so that users can login into a different account
                googleAuthMan.signOut()
            }
            
            try? Auth.auth().signOut()
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ui.lighterLavBlue.ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                
                
                GeometryReader { geo in
                    VStack(alignment: .leading) {
                        
                        // TEMP LOGOUT BUTTON
                        Button {
                            logout()
                        } label: {
                            Text("Logout")
                        }
                        .padding(.leading, 50)
                        
                        if (envName != "prod") {
                            Text("\(envName)")
                                .padding(.leading, 16)
                                .padding(.top, 6)
                                .font(.ui.graphikLightItalic)
                                .foregroundColor(Color.ui.richBlack)
                        }
                        
                        Text("Which social media platform is this for?")
                            .padding(.leading, 16)
                            .padding(.top, 6)
                            .font(.ui.graphikSemibold)
                            .foregroundColor(Color.ui.richBlack)
                        
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
                        
                        BottomAreaView(expandArea: $expandBottomArea, platformSelected: $platformSelected, promptText: $promptText)
                            .frame(maxHeight: geo.size.height)
                    }
                    
                }
                .scrollDismissesKeyboard(.interactively)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .onTapGesture {
                expandBottomArea = false
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(platformSelected: SocialMediaPlatforms.init().platforms[0])
        
        HomeView(platformSelected: SocialMediaPlatforms.init().platforms[0])
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
