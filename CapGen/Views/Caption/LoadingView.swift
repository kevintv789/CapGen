//
//  LoadingView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Heap
import NavigationStack
import SwiftUI

struct LoadingView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var openAiRequest: OpenAIConnector
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel
    @EnvironmentObject var photosSelectionVm: PhotoSelectionViewModel
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var taglistVM: TaglistViewModel

    var captionGenType: CaptionGenerationType = .prompt

    @State var showCaptionView: Bool = false
    @State var openAiResponse: String?
    @State var router: Router? = nil

    private func callOpenAi(with openAiPrompt: String, decrementCreditBy: Int64) async {
        if !openAiPrompt.isEmpty {
            let openAiResponse = await openAiRequest.processPrompt(apiKey: firestoreMan.openAiKey, prompt: openAiPrompt)

            if let error = openAiRequest.appError?.error {
                switch error {
                case .capacityError:
                    router?.toCapacityFallbackView()
                default:
                    router?.toGenericFallbackView()
                }
            }

            if openAiResponse != nil && !openAiResponse!.isEmpty {
                // Process the response into arrays
                let _ = await openAiRequest.processOutputIntoArray(openAiResponse: openAiResponse)

                // Conform all captions to the required minimum word count
                await openAiRequest.updateCaptionBasedOnWordCountIfNecessary(apiKey: firestoreMan.openAiKey) {
                    // decrement credit on success
                    firestoreMan.decrementCredit(for: AuthManager.shared.userManager.user?.id as? String ?? nil, value: decrementCreditBy)

                    // Navigate to Caption View
                    self.navStack.push(CaptionView())
                }
            }
        }
    }

    private func generateCaptionFromPrompt() async {
        Heap.track("onAppear LoadingView - Currently loading captions from PROMPT")

        router = Router(navStack: navStack)

        // Reset all previous responses
        openAiRequest.resetResponse()

        // Generate prompt
        let openAiPrompt = openAiRequest.generatePrompt(userInputPrompt: genPromptVm.promptInput, tones: genPromptVm.selectdTones, includeEmojis: genPromptVm.includeEmojis, includeHashtags: genPromptVm.includeHashtags, captionLength: genPromptVm.captionLengthValue, captionLengthType: genPromptVm.captionLengthType)

        await callOpenAi(with: openAiPrompt, decrementCreditBy: -1)
    }

    private func generateCaptionFromImage() async {
        // Call Google's Vision AI to detect aspects of image
        var imageData: Data?
        // To determine which image data to use (camera or photo library), store the image data for the one that is not nil
        if photosSelectionVm.photosPickerData != nil {
            imageData = photosSelectionVm.photosPickerData
        } else if !cameraViewModel.imageData.isEmpty {
            imageData = cameraViewModel.imageData
        }

        if let imageData = imageData, let uiImage = UIImage(data: imageData), let apiKey = firestoreMan.googleApiKey {
            do {
                let json = try await photosSelectionVm.analyzeImage(image: uiImage, apiKey: apiKey)

                let jsonString = """
                {
                  "labels": \(json["responses"][0]["labelAnnotations"]),
                  "landmarks": \(json["responses"][0]["landmarkAnnotations"]),
                  "faceAnnotations": \(json["responses"][0]["faceAnnotations"]),
                  "textAnnotations": \(json["responses"][0]["textAnnotations"]),
                  "safeSearchAnnotations": \(json["responses"][0]["safeSearchAnnotation"]),
                }
                """
                photosSelectionVm.decodeGoogleVisionData(from: jsonString)
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }

        if let visionData = photosSelectionVm.visionData {
            // Generate prompt
            var imageAddress: ImageGeoLocationAddress?
            if photosSelectionVm.imageAddress != nil {
                imageAddress = photosSelectionVm.imageAddress!
            } else if cameraViewModel.imageAddress != nil {
                imageAddress = cameraViewModel.imageAddress!
            }

            let openAiPrompt = openAiRequest.generatePromptForImage(tones: genPromptVm.selectdTones, includeEmojis: genPromptVm.includeEmojis, includeHashtags: genPromptVm.includeHashtags, captionLength: genPromptVm.captionLengthValue, captionLengthType: genPromptVm.captionLengthType, visionData: visionData, imageAddress: imageAddress, customTags: taglistVM.combinedTagTypes)

            await callOpenAi(with: openAiPrompt, decrementCreditBy: -2)
        } else {
            // if vision data is not available, then only use custom tags
        }
    }

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
                Task {
                    if captionGenType == .prompt {
                        await generateCaptionFromPrompt()
                    } else if captionGenType == .image {
                        await generateCaptionFromImage()
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
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(CameraViewModel())
            .environmentObject(TaglistViewModel())

        LoadingView()
            .environmentObject(OpenAIConnector())
            .environmentObject(NavigationStackCompat())
            .environmentObject(FirestoreManager())
            .environmentObject(GenerateByPromptViewModel())
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(CameraViewModel())
            .environmentObject(TaglistViewModel())
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
