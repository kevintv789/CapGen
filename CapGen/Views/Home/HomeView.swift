//
//  HomeView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/11/23.
//

import FirebaseAuth
import Heap
import NavigationStack
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var savedCaptionHomeVm: SavedCaptionHomeViewModel
    @EnvironmentObject var generateByPromptVm: GenerateByPromptViewModel
    @EnvironmentObject var photoSelectionVm: PhotoSelectionViewModel

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
    @State var showPaymentView: Bool = false

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
                    .padding(.horizontal)

                    // Greetings view
                    GreetingsHomeView(userName: self.userFirstName ?? "user")
                        .padding()
                        .padding(.horizontal)

                    // Credits view
                    Button {
                        Haptics.shared.play(.soft)
                        self.showPaymentView = true
                    } label: {
                        CreditsView(creditAmount: self.creditAmount ?? 0)
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            // Generate catpions via Prompt button
                            GenerateCaptionsButtonView(title: "Create captions with a prompt", imgName: "gen_captions_robot", requiredCredits: 1) {
                                self.generateByPromptVm.resetAll()

                                if let creditAmount = self.creditAmount, creditAmount < 1 {
                                    self.showCreditsDepletedBottomSheet = true
                                } else {
                                    // Navigate to generate captions views
                                    self.navStack.push(EnterPromptView())
                                }
                            }
                            .padding(.trailing)

                            // Generate captions via Images button
                            GenerateCaptionsButtonView(title: "Create captions using your images", imgName: "camera_robot", requiredCredits: 2) {
                                self.generateByPromptVm.resetAll()

                                if let creditAmount = self.creditAmount, creditAmount < 2 {
                                    self.showCreditsDepletedBottomSheet = true
                                } else {
                                    // Navigate to generate captions views
                                    self.navStack.push(ImageSelectorView())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .ignoresSafeArea(.all)
                }

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

            Heap.track("onAppear HomeView")
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
                
                // Initialize folders
                FolderViewModel.shared.folders = user.folders

                // Map Firebase User ID to Heap
                Heap.identify(user.id)
                Heap.addUserProperties(["email": user.email, "name": user.fullName])
            }
        }
        // show the payment view if not enough credits
        .fullScreenCover(isPresented: $showCreditsDepletedBottomSheet) {
            PaymentView(title: "Oops! You don't have enough credits", subtitle: "Get more to keep creating amazing captions")
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
                if !FolderViewModel.shared.currentFolder.id.isEmpty {
                    let uid = AuthManager.shared.userManager.user?.id ?? nil
                    let currentFolders = authManager.userManager.user?.folders ?? []

                    firestoreManager.onFolderDelete(for: uid, curFolder: FolderViewModel.shared.currentFolder, currentFolders: currentFolders) {
                        withAnimation {
                            self.showFolderDeleteModal = false
                            Heap.track("onClick HomeView - Successfully deleted folder", withProperties: ["folder_to_delete": FolderViewModel.shared.currentFolder])
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
                if let user = AuthManager.shared.userManager.user, let captionToBeRemoved = FolderViewModel.shared.captionToBeDeleted {
                    let uid = user.id
                    firestoreManager.deleteSingleCaption(for: uid, captionToBeRemoved: captionToBeRemoved) {
                        withAnimation {
                            FolderViewModel.shared.resetCaptionToBeDeleted()
                            self.showCaptionDeleteModal = false

                            Heap.track("onClick HomeView - Successfully deleted caption", withProperties: ["caption_to_delete": captionToBeRemoved])
                        }
                    }
                }
            })
        } onClickExit: {
            withAnimation {
                self.showCaptionDeleteModal = false
            }
        }
        .onReceive(FolderViewModel.shared.$isDeleting) { value in
            // Assign published value to a State to use in the onClickExit() function from modalView
            // This is a necessary work around for modifying published state during a view update
            self.showFolderDeleteModal = value
        }
        .onChange(of: self.showFolderDeleteModal) { newValue in
            // Resets the published value back to original state when the delete modal disappears
            FolderViewModel.shared.isDeleting = newValue
        }
        // show full image on click
        .overlay(
            FullScreenImageOverlay(isFullScreenImage: $photoSelectionVm.showImageInFullScreen, image: photoSelectionVm.fullscreenImageClicked, imageHeight: .constant(nil))
        )
        // show payment view
        .fullScreenCover(isPresented: $showPaymentView) {
            // Present the CameraViewController, binding the captured image to the capturedImage property.
            PaymentView()
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
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(NavigationStackCompat())
            .environmentObject(AuthManager.shared)
            .environmentObject(FolderViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
            .environmentObject(GenerateByPromptViewModel())
            .environmentObject(PhotoSelectionViewModel())
        
        HomeView()
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(NavigationStackCompat())
            .environmentObject(AuthManager.shared)
            .environmentObject(FolderViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
            .environmentObject(GenerateByPromptViewModel())
            .environmentObject(PhotoSelectionViewModel())
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

            Text(creditAmount > 1 ? "\(creditAmount) credits" : "\(creditAmount) credit")
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
    let requiredCredits: Int
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.play(.soft)
            action()
        } label: {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.ui.middleBluePurple)
                .frame(width: 220, height: 220)
                .shadow(color: Color.ui.richBlack.opacity(0.45), radius: 4, x: 2, y: 4)
                .overlay(
                    VStack(spacing: 0) {
                        Text(title)
                            .font(.ui.headline)
                            .foregroundColor(.ui.cultured)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()

                        ZStack {
                            Circle()
                                .fill(Color.ui.lavenderBlue)
                                .frame(width: 135, height: 135)
                                .blur(radius: 35)

                            Image(imgName)
                                .resizable()
                                .frame(width: 135, height: 135)
                        }
                        .padding(-20)

                        // Coin image
                        if requiredCredits > 0 {
                            VStack {
                                Spacer()

                                HStack(spacing: -10) {
                                    Spacer()

                                    ForEach(0 ..< requiredCredits, id: \.self) { _ in
                                        Image("coin-icon")
                                            .resizable()
                                            .frame(width: 50, height: 45)
                                            .padding(.bottom, 10)
                                    }
                                }
                            }
                        }
                    }
                )
        }
    }
}
