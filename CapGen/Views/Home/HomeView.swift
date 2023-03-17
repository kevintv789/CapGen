//
//  HomeView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/11/23.
//

import FirebaseAuth
import NavigationStack
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var folderVm: FolderViewModel
    @EnvironmentObject var savedCaptionHomeVm: SavedCaptionHomeViewModel

    // user data
    @State var userFirstName: String?
    @State var creditAmount: Int?

    // show modal requests
    @State var showRefillModal: Bool = false
    @State var showCongratsModal: Bool = false
    @State var showFolderDeleteModal: Bool = false

    // nav instances
    @State var router: Router? = nil

    // private instances
    @State var showCaptionDeleteModal: Bool = false
    @State var showCreditsDepletedBottomSheet: Bool = false

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
                        if let creditAmount = self.creditAmount, creditAmount < 1 {
                            self.showCreditsDepletedBottomSheet = true
                        } else {
                            // Navigate to generate captions views
                            self.navStack.push(EnterPromptView())
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)

                Spacer()
            }

            VStack {
                Spacer()
                // Bottom level
                Wave(isExpanded: savedCaptionHomeVm.isViewExpanded)
                    .fill(Color.ui.lavenderBlue)
                    .rotationEffect(.degrees(180))
                    .ignoresSafeArea(.all)
                    .frame(height: savedCaptionHomeVm.isViewExpanded ? SCREEN_HEIGHT : SCREEN_HEIGHT * 0.34)
                    .overlay(
                        SavedCaptionsHomeView(showCaptionDeleteModal: $showCaptionDeleteModal)
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
        // show the depleted credit amount modal
        .sheet(isPresented: $showCreditsDepletedBottomSheet) {
            CreditsDepletedModalView(isViewPresented: $showCreditsDepletedBottomSheet)
                .presentationDetents([.fraction(SCREEN_HEIGHT < 700 ? 0.75 : 0.5)])
        }
        // Show credits refill modal
        .modalView(horizontalPadding: 40, show: $showRefillModal) {
            RefillModalView(isViewPresented: $showRefillModal, showCongratsModal: $showCongratsModal)
        } onClickExit: {
            withAnimation {
                self.showRefillModal = false
            }
        }
        // Show congrats modal after ad
        .modalView(horizontalPadding: 40, show: $showCongratsModal) {
            CongratsModalView(showView: $showCongratsModal)
        } onClickExit: {
            withAnimation {
                self.showCongratsModal = false
            }
        }
        // Show folder delete modal
        .modalView(horizontalPadding: 40, show: $showFolderDeleteModal) {
            DeleteModalView(title: "Remove folder", subTitle: "Deleting this folder will permanently erase all of its contents. Are you sure you want to proceed? 🫢", lottieFile: "crane_hand_lottie", showView: $showFolderDeleteModal, onDelete: {
                if !folderVm.currentFolder.id.isEmpty {
                    let uid = AuthManager.shared.userManager.user?.id ?? nil
                    let currentFolders = authManager.userManager.user?.folders ?? []
                    
                    firestoreManager.onFolderDelete(for: uid, curFolder: folderVm.currentFolder, currentFolders: currentFolders) {
                        withAnimation {
                            self.showFolderDeleteModal = false
                        }
                    }
                }
                
            })
        } onClickExit: {
            withAnimation {
                self.showFolderDeleteModal = false
            }
        }
        // Show caption delete modal
        .modalView(horizontalPadding: 40, show: $showCaptionDeleteModal) {
            DeleteModalView(title: "Delete caption", subTitle: "Are you sure you want to delete this caption? 🫢 This action cannot be undone.", lottieFile: "crane_hand_lottie", showView: $showCaptionDeleteModal, onDelete: {
                if let user = AuthManager.shared.userManager.user, let captionToBeRemoved = folderVm.captionToBeDeleted {
                    let uid = user.id
                    firestoreManager.deleteSingleCaption(for: uid, captionToBeRemoved: captionToBeRemoved) {
                        withAnimation {
                            folderVm.resetCaptionToBeDeleted()
                            self.showCaptionDeleteModal = false
                        }
                    }
                }
            })
        } onClickExit: {
            withAnimation {
                self.showCaptionDeleteModal = false
            }
        }
        .onReceive(folderVm.$isDeleting) { value in
            // Assign published value to a State to use in the onClickExit() function from modalView
            // This is a necessary work around for modifying published state during a view update
            self.showFolderDeleteModal = value
        }
        .onChange(of: self.showFolderDeleteModal) { newValue in
            // Resets the published value back to original state when the delete modal disappears
            folderVm.isDeleting = newValue
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
            .environmentObject(FirestoreManager())
            .environmentObject(NavigationStackCompat())
            .environmentObject(AuthManager.shared)
            .environmentObject(FolderViewModel())
            .environmentObject(SavedCaptionHomeViewModel())

        HomeView()
            .environmentObject(FirestoreManager())
            .environmentObject(NavigationStackCompat())
            .environmentObject(AuthManager.shared)
            .environmentObject(FolderViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
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
