//
//  LoadingView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import NavigationStack
import SwiftUI

struct LoadingView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var openAiRequest: OpenAIConnector
    @EnvironmentObject var navStack: NavigationStackCompat
    @State var showCaptionView: Bool = false
    @State var openAiResponse: String?
    @State var router: Router? = nil

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                Color.ui.cultured.ignoresSafeArea(.all)

                VStack {
                    LottieView(name: "loading_paperplane", loopMode: .loop, isAnimating: true)
                        .frame(width: SCREEN_WIDTH, height: 300)

                    Text("Hang tight!")
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.title)
                        .padding(.bottom, 15)

                    Text("Your captions are on the way")
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.headlineRegular)
                }
                .padding(.top, 100)
            }
            .onAppear {
                self.router = Router(navStack: navStack)

                Task {
                    if !openAiRequest.prompt.isEmpty {
                        openAiResponse = await openAiRequest.processPrompt(apiKey: firestoreMan.openAiKey)

                        if let error = openAiRequest.appError?.error {
                            switch error {
                            case .capacityError:
                                self.router?.toCapacityFallbackView()
                            default:
                                self.router?.toGenericFallbackView()
                            }
                        }

                        if openAiResponse != nil && !openAiResponse!.isEmpty {
                            // decrement credit on success
                            firestoreMan.decrementCredit(for: AuthManager.shared.userManager.user?.id as? String ?? nil)
                            self.navStack.push(CaptionView(captionStr: $openAiResponse, platform: openAiRequest.requestModel.platform))
                        }
                    }
                }
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .environmentObject(OpenAIConnector())
            .environmentObject(NavigationStackCompat())
            .environmentObject(FirestoreManager())

        LoadingView()
            .environmentObject(OpenAIConnector())
            .environmentObject(NavigationStackCompat())
            .environmentObject(FirestoreManager())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct SpinnerCircle: View {
    var start: CGFloat
    var end: CGFloat
    var rotation: Angle
    var color: Color

    var body: some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
            .fill(color)
            .rotationEffect(rotation)
    }
}
