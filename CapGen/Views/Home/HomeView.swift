//
//  HomeView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/11/23.
//

/**
 OLD CODE

 @State var router: Router? = nil

 @FocusState private var isKeyboardFocused: Bool
 @State var expandBottomArea: Bool = false
 @State var showRefillModal: Bool = false
 @State var showCongratsModal: Bool = false
 @State var isAdLoading: Bool = false

 @FocusState private var isFocused: Bool
 @ScaledMetric var platformScrollViewHeight: CGFloat = 75

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
                                         self.captionConfigs.platformSelected = platform.title
                                     }

                                 } label: {
                                     Pill(title: platform.title, isToggled: platform.title == self.captionConfigs.platformSelected)
                                 }
                                 .id(platform.title)
                             }
                         }
                         .padding()
                     }
                     .onChange(of: self.captionConfigs.platformSelected) { value in
                         withAnimation {
                             scrollProxy.scrollTo(value, anchor: .center)
                         }

                         Haptics.shared.play(.soft)
                     }
                     .frame(height: platformScrollViewHeight)
                 }

                  Create a Text Area view that is the main component for typing input
                 TextAreaView(text: $captionConfigs.promptText)
                     .frame(width: SCREEN_WIDTH / 1.1, height: SCREEN_HEIGHT / 2)
                     .position(x: SCREEN_WIDTH / 2, y: SCREEN_HEIGHT / 4)
                     .focused($isFocused)
                     .onTapGesture {
                         withAnimation(.interpolatingSpring(stiffness: 200, damping: 300)) {
                             self.expandBottomArea = false
                         }
                     }

                 BottomAreaView(expandArea: $expandBottomArea, platformSelected: $captionConfigs.platformSelected, promptText: $captionConfigs.promptText, credits: $credits, isAdLoading: $isAdLoading)
                     .frame(maxHeight: SCREEN_HEIGHT)
             }
             .scrollDismissesKeyboard(.interactively)
             .ignoresSafeArea(.keyboard, edges: .bottom)
         }
         .onAppear {
             self.router = Router(navStack: navStack)

             if AuthManager.shared.isSignedIn ?? false {
                 firestoreManager.fetchKey()
             }
         }
         .onReceive(firestoreManager.$appError, perform: { value in
             if let error = value?.error {
                 if error == .genericError {
                     self.router?.toGenericFallbackView()
                 }
             }
         })
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
 */

import FirebaseAuth
import NavigationStack
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionConfigs: CaptionConfigsViewModel

    // user data
    @State var userFirstName: String?
    @State var creditAmount: Int?

    // show modal requests
    @State var showRefillModal: Bool = false
    @State var showCongratsModal: Bool = false

    // nav instances
    @State var router: Router? = nil

    // saved captions bottom view
    @State var isExpanded: Bool = false

    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea()

            // Main container
            VStack {
                // Top level
                VStack(alignment: .leading) {
                    // Create header with profile button
                    HStack {
                        LogoView()

                        Spacer()

                        // navigate to profile view
                        PushView(destination: ProfileView()) {
                            Image("profile")
                                .resizable()
                                .frame(width: 30, height: 30)
                        }
                        .simultaneousGesture(TapGesture().onEnded { _ in
                            Haptics.shared.play(.soft)
                        })
                    }

                    // Greetings view
                    GreetingsHomeView(userName: self.userFirstName ?? "user")
                        .padding()

                    // Credits view
                    Button {
                        Haptics.shared.play(.soft)
                        self.showRefillModal = true
                    } label: {
                        CreditsView(creditAmount: self.creditAmount ?? 0)
                    }

                    // Generate captions button
                    GenerateCaptionsButtonView(title: "Create captions with a prompt", imgName: "gen_captions_robot") {
                        // Navigate to generate captions views
                    }
                    .padding()
                }
                .padding(.horizontal)

                Spacer()
            }

            VStack {
                Spacer()
                // Bottom level
                Wave(isExpanded: self.isExpanded)
                    .fill(Color.ui.lavenderBlue)
                    .rotationEffect(.degrees(180))
                    .ignoresSafeArea(.all)
                    .frame(height: isExpanded ? SCREEN_HEIGHT : SCREEN_HEIGHT * 0.34)
                    .overlay(
                        SavedCaptionsHomeView(isExpanded: self.$isExpanded)
                    )
            }
        }
        .onAppear {
            // Initialize router instance for nav
            self.router = Router(navStack: navStack)

            if authManager.isSignedIn ?? false {
                firestoreManager.fetchKey()
            }
        }
        .onReceive(firestoreManager.$appError, perform: { value in
            if let error = value?.error {
                // Navigates the user to error page
                if error == .genericError {
                    self.router?.toGenericFallbackView()
                }
            }
        })
        .onReceive(authManager.userManager.$user) { user in
            if let user = user {
                // Retrieves user's first name
                self.userFirstName = user.fullName.components(separatedBy: " ")[0]

                // Retrieves user's credit amount
                self.creditAmount = user.credits
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
    }
}

struct Wave: Shape {
    var isExpanded: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: .zero)

        // Draw a line from top left to top right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Draw a line from top right to bottom right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        if isExpanded {
            // Draw straight line
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            // Draw curve
            path.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                          control1: CGPoint(x: rect.maxX * 0.55, y: rect.midY * 1.5),
                          control2: CGPoint(x: rect.maxX * 0.25, y: rect.maxY * 1.15))
        }

        // Draw left border line
        path.closeSubpath()

        return path
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(TaglistViewModel())
            .environmentObject(CaptionConfigsViewModel())
            .environmentObject(FirestoreManager())
            .environmentObject(CaptionConfigsViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(AuthManager.shared)

        HomeView()
            .environmentObject(TaglistViewModel())
            .environmentObject(CaptionConfigsViewModel())
            .environmentObject(FirestoreManager())
            .environmentObject(CaptionConfigsViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(AuthManager.shared)
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct GreetingsHomeView: View {
    let timeOfDay = calculateTimeOfDay()
    let userName: String

    private func createGreetings() -> String {
        switch timeOfDay {
        case .morning:
            return "Good morning"
        case .afternoon:
            return "Good afternoon"
        case .evening:
            return "Good evening"
        }
    }

    private func createGreetingsIcon() -> String {
        switch timeOfDay {
        case .morning:
            return "sunrise"
        case .afternoon:
            return "sun"
        case .evening:
            return "moon"
        }
    }

    var body: some View {
        HStack {
            Image(createGreetingsIcon())
                .resizable()
                .frame(width: 35, height: 35)

            Text("\(createGreetings()), \(userName)!")
                .font(.ui.headline)
                .foregroundColor(.ui.richBlack)
                .padding(.leading, 7)
                .lineLimit(2)
        }
    }
}

struct CreditsView: View {
    let creditAmount: Int

    var body: some View {
        HStack(spacing: 0) {
            LottieView(name: "piggy_bank_lottie", loopMode: .playOnce, isAnimating: true)
                .frame(width: 65, height: 65)

            CreditsTextView(creditAmount: creditAmount)
                .multilineTextAlignment(.leading)
                .lineSpacing(5)
        }
        .padding(.top, -10)
    }
}

struct CreditsTextView: View {
    let creditAmount: Int

    var body: some View {
        Text("You have ")
            .foregroundColor(.ui.cadetBlueCrayola)
            .font(.ui.headline)

            +

            Text(creditAmount > 0 ? "\(creditAmount) credits" : "\(creditAmount) credit")
            .foregroundColor(.ui.orangeWeb)
            .font(.ui.headline)

            +

            Text(" remaining.\nClick here to get more!")
            .foregroundColor(.ui.cadetBlueCrayola)
            .font(.ui.headline)
    }
}

struct GenerateCaptionsButtonView: View {
    let title: String
    let imgName: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.play(.soft)
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.ui.middleBluePurple)
                    .frame(width: 220, height: 220)
                    .shadow(color: Color.ui.richBlack.opacity(0.45), radius: 4, x: 2, y: 4)
                    .overlay(
                        VStack(spacing: 0) {
                            HStack {
                                Text(title)
                                    .font(.ui.headline)
                                    .foregroundColor(.ui.cultured)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                                    .frame(width: 20)

                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 15, height: 15)
                                    .foregroundColor(.ui.cultured)
                                    .background(
                                        Circle()
                                            .fill(Color.ui.lavenderBlue)
                                            .frame(width: 30, height: 30)
                                    )
                            }
                            .padding()

                            Spacer()
                        }
                    )

                Image(imgName)
                    .resizable()
                    .frame(width: 170, height: 170)
                    .background(
                        Circle()
                            .fill(Color.ui.lavenderBlue)
                            .frame(width: 150, height: 150)
                            .blur(radius: 35)
                    )
                    .padding(.top, 45)
            }
        }
    }
}
