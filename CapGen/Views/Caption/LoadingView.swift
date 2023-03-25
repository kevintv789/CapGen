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
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel

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
                        .padding(.bottom, 8)

                    Text("Please wait, this may take a few minutes")
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.headlineRegular)
                }
                .padding(.top, 100)
            }
            .onReceive(openAiRequest.$appError, perform: { value in
                if let error = value?.error {
                    // Navigates the user to error page
                    if error == .genericError {
                        self.router?.toGenericFallbackView()
                    }
                }
            })
            .onAppear {
                self.router = Router(navStack: navStack)

                // Reset all previous responses
                openAiRequest.resetResponse()

                Task {
                    // Generate prompt
                    let openAiPrompt = openAiRequest.generatePrompt(userInputPrompt: genPromptVm.promptInput, tones: genPromptVm.selectdTones, includeEmojis: genPromptVm.includeEmojis, includeHashtags: genPromptVm.includeHashtags, captionLength: genPromptVm.captionLengthValue, captionLengthType: genPromptVm.captionLengthType)

                    if !openAiPrompt.isEmpty {
                        let openAiResponse = await openAiRequest.processPrompt(apiKey: firestoreMan.openAiKey, prompt: openAiPrompt)

                        if let error = openAiRequest.appError?.error {
                            switch error {
                            case .capacityError:
                                self.router?.toCapacityFallbackView()
                            default:
                                self.router?.toGenericFallbackView()
                            }
                        }

                        if openAiResponse != nil && !openAiResponse!.isEmpty {
                            // Process the response into arrays
                            let _ = await openAiRequest.processOutputIntoArray(openAiResponse: openAiResponse)

                            // Conform all captions to the required minimum word count
                            await openAiRequest.updateCaptionBasedOnWordCountIfNecessary(apiKey: firestoreMan.openAiKey) {
                                // decrement credit on success
                                firestoreMan.decrementCredit(for: AuthManager.shared.userManager.user?.id as? String ?? nil)

                                // Navigate to Caption View
                                self.navStack.push(CaptionView())
                            }
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
            .environmentObject(GenerateByPromptViewModel())

        LoadingView()
            .environmentObject(OpenAIConnector())
            .environmentObject(NavigationStackCompat())
            .environmentObject(FirestoreManager())
            .environmentObject(GenerateByPromptViewModel())
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
