//
//  BottomAreaView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import NavigationStack
import SwiftUI

let MIN_HEIGHT: CGFloat = SCREEN_HEIGHT * 0.2
let MAX_HEIGHT: CGFloat = SCREEN_HEIGHT * 0.7

extension View {
    func dropInAndOutAnimation(value: Bool) -> some View {
        animation(.easeInOut(duration: 0.35), value: value)
    }
}

extension Text {
    func headerStyle() -> some View {
        foregroundColor(.ui.cultured)
            .font(.ui.title4)
    }
}

struct BottomAreaView: View {
    @ObservedObject var ad = AppodealProvider.shared
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var openAiConnector: OpenAIConnector
    @EnvironmentObject var navStack: NavigationStackCompat

    @State var router: Router? = nil

    @Binding var expandArea: Bool
    @Binding var platformSelected: String
    @Binding var promptText: String
    @Binding var credits: Int
    @Binding var isAdLoading: Bool

    @State var lengthValue: String = ""
    @State var captionLengthType: String = ""
    @State var tonesSelected: [ToneModel] = []
    @State var includeEmojis: Bool = false
    @State var includeHashtags: Bool = false

    @State var showCreditsDepletedBottomSheet: Bool = false

    @State var isShowingAdFromBottomView: Bool = false

    func mapAllRequests() {
        // Zero out all sizes for tones since it's not needed at this point and will cause database conflicts during edit
        var modifiedSelectedTones: [ToneModel] = []
        tonesSelected.forEach { tone in
            let newTone = ToneModel(id: tone.id, title: tone.title, description: tone.description, icon: tone.icon, size: 0)
            modifiedSelectedTones.append(newTone)
        }

        openAiConnector.generatePrompt(platform: platformSelected, prompt: promptText, tones: modifiedSelectedTones, includeEmojis: includeEmojis, includeHashtags: includeHashtags, captionLength: lengthValue, captionLengthType: captionLengthType)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.richBlack
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .overlay(
                    ZStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 20) {
                                ToneSelectionSection(tonesSelected: $tonesSelected)
                                    .dropInAndOutAnimation(value: expandArea)

                                EmojisAndHashtagSection(includeEmoji: $includeEmojis, includeHashtag: $includeHashtags)
                                    .dropInAndOutAnimation(value: expandArea)

                                LengthSelectionSection(lengthValue: $lengthValue, captionLengthType: $captionLengthType)
                                    .dropInAndOutAnimation(value: expandArea)

                                // Play/Submit button
                                Button {
                                    Haptics.shared.play(.soft)

                                    guard let userManager = AuthManager.shared.userManager.user else { return }
                                    mapAllRequests()
                                    isShowingAdFromBottomView = true
                                    if credits < 1 {
                                        // Only show the bottom sheet modal if user has not selected 'Just play ad next time'
                                        if userManager.userPrefs.showCreditDepletedModal {
                                            self.showCreditsDepletedBottomSheet = true
                                        } else {
                                            // play ad and display load view
                                            if self.ad.isRewardedReady {
                                                self.ad.presentRewarded()
                                            } else {
                                                self.isAdLoading = true
                                            }
                                        }
                                    } else {
                                        self.router?.toLoadingView()
                                    }

                                } label: {
                                    Image("submit-btn-1")
                                        .resizable()
                                        .frame(width: 90, height: 90)
                                }
                                .dropInAndOutAnimation(value: expandArea)
                            }
                            .offset(x: 0, y: expandArea ? 0 : SCREEN_HEIGHT)
                            .padding(.top, 50)
                        }
                        .padding(.bottom, 50)
                        .scrollDisabled(!expandArea)
                        .clipped()

                        ExpandButton(expandArea: $expandArea)
                            .offset(x: 0, y: expandArea ? -MAX_HEIGHT / 2 : -MIN_HEIGHT / 2)
                            .dropInAndOutAnimation(value: expandArea)

                        if !expandArea {
                            TabButtonsView()
                                .padding(.bottom, SCREEN_HEIGHT < 700 ? 50 : 80)
                        }
                    }
                )
                .frame(height: expandArea ? MAX_HEIGHT : MIN_HEIGHT)
                .offset(x: 0, y: expandArea ? 50 : MIN_HEIGHT / 1.2)
        }
        .onAppear {
            self.router = Router(navStack: self.navStack)
        }
        .onReceive(self.ad.$isRewardedVideoFinished, perform: { isFinished in
            // use isShowingAdFromBottomView to determine the context on when to show loading view
            // we only want to show loadingView() upon press of the bottom view button
            if isFinished && isShowingAdFromBottomView {
                self.showCreditsDepletedBottomSheet = false
                self.router?.toLoadingView()
            }
        })
        .onReceive(self.ad.$appError) { value in
            if let error = value?.error {
                if error == .genericError {
                    self.router?.toGenericFallbackView()
                }
            }
        }
        .onReceive(self.ad.$isRewardedReady, perform: { isReady in
            if isReady && isShowingAdFromBottomView {
                self.isAdLoading = false
            }
        })
        .onChange(of: self.isAdLoading, perform: { isLoading in
            if !isLoading && isShowingAdFromBottomView {
                self.ad.presentRewarded()
            }
        })
        .sheet(isPresented: $showCreditsDepletedBottomSheet) {
            CreditsDepletedModalView(isViewPresented: $showCreditsDepletedBottomSheet)
                .presentationDetents([.fraction(SCREEN_HEIGHT < 700 ? 0.75 : 0.5)])
        }
        .ignoresSafeArea(.all)
    }
}

struct TabButtonsView: View {
    @State var hasCaptions: Bool = false
    @ScaledMetric var scaledSize: CGFloat = 1

    var body: some View {
        HStack(alignment: .center) {
            if hasCaptions {
                PushView(destination: PopulatedCaptionsView()) {
                    Image("saved-captions-tab-icon")
                        .resizable()
                        .frame(width: 40 * scaledSize, height: 40 * scaledSize)
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    Haptics.shared.play(.soft)
                })
            } else {
                PushView(destination: EmptyCaptionsView()) {
                    Image("saved-captions-tab-icon")
                        .resizable()
                        .frame(width: 40 * scaledSize, height: 40 * scaledSize)
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    Haptics.shared.play(.soft)
                })
            }

            Spacer()
                .frame(width: SCREEN_WIDTH / 2)

            PushView(destination: ProfileView()) {
                Image("profile-tab-icon")
                    .resizable()
                    .frame(width: 43 * scaledSize, height: 43 * scaledSize)
                    .foregroundColor(.ui.cultured)
            }
            .simultaneousGesture(TapGesture().onEnded { _ in
                Haptics.shared.play(.soft)
            })
        }
        .onReceive(AuthManager.shared.userManager.$user, perform: { user in
            if let cg = user?.captionsGroup, !cg.isEmpty {
                self.hasCaptions = true
            }
        })
    }
}

struct ExpandButton: View {
    @Binding var expandArea: Bool
    @State var showText: Bool = false

    @ScaledMetric var buttonSize: CGFloat = 80
    @ScaledMetric var chevronSizeExpanded: CGFloat = 40
    @ScaledMetric var chevronSize: CGFloat = 30

    var body: some View {
        Button {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 300)) {
                expandArea.toggle()
            }

            Haptics.shared.play(.soft)
        } label: {
            Circle()
                .strokeBorder(Color.ui.lighterLavBlue.opacity(0.5), lineWidth: 4)
                .background(
                    Circle()
                        .strokeBorder(Color.ui.cultured, lineWidth: 4)
                        .background(
                            Circle()
                                .fill(Color.ui.richBlack)
                        )
                )
                .overlay(
                    VStack(spacing: 3) {
                        Image("chevron-up-white")
                            .resizable()
                            .frame(width: expandArea ? chevronSizeExpanded : chevronSize, height: expandArea ? chevronSizeExpanded : chevronSize)
                            .rotationEffect(.degrees(expandArea ? -180 : 0))

                        if showText {
                            Text("Next")
                                .foregroundColor(.ui.cultured)
                                .font(.ui.headlineBold)
                        }
                    }
                    .offset(y: expandArea ? 0 : -5)
                )
                .frame(width: buttonSize, height: buttonSize)
        }
        .animation(.interpolatingSpring(stiffness: 200, damping: 300), value: expandArea)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                withAnimation {
                    self.showText = !expandArea
                }
            }
        }
    }
}

struct ToneSelectionSection: View {
    @EnvironmentObject var taglistVM: TaglistViewModel
    @Binding var tonesSelected: [ToneModel]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Choose up to 2 tones")
                .headerStyle()
                .padding()

            VStack(alignment: .leading, spacing: 15) {
                ForEach(taglistVM.rows, id: \.self) { rows in
                    HStack(spacing: 15) {
                        ForEach(rows) { tone in
                            Button {
                                Haptics.shared.play(.soft)

                                // Don't select the same tone again
                                if !tonesSelected.contains(tone) {
                                    tonesSelected.append(tone)
                                } else {
                                    // If an already existing item is selected, then remove
                                    self.tonesSelected = tonesSelected.filter { $0 != tone }
                                }

                                // Remove first selected item to keep it at a maximum of 2 selections
                                if tonesSelected.count > 2 {
                                    tonesSelected.remove(at: 0)
                                }
                            } label: {
                                Text("\(tone.icon) \(tone.title)")
                                    .foregroundColor(tonesSelected.contains(tone) ? .ui.cultured : .ui.richBlack)
                                    .font(.ui.headline)
                                    .padding(.leading, 14)
                                    .padding(.trailing, 15)
                                    .padding(.vertical, 10)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(tonesSelected.contains(tone) ? Color.ui.middleBluePurple : Color.ui.cultured)

                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.ui.cultured, lineWidth: tonesSelected.contains(tone) ? 3 : 0)
                                        }
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            self.taglistVM.getTags()
        }
    }
}

struct EmojisAndHashtagSection: View {
    @Binding var includeEmoji: Bool
    @Binding var includeHashtag: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Emojis?")
                    .headerStyle()
                    .padding()

                HStack(spacing: 15) {
                    Button {
                        Haptics.shared.play(.soft)
                        includeEmoji = false
                    } label: {
                        RectangleCard(title: "", description: nil, isSelected: !includeEmoji)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image("no-emoji")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                            )
                    }

                    Button {
                        Haptics.shared.play(.soft)
                        includeEmoji = true
                    } label: {
                        RectangleCard(title: "", description: nil, isSelected: includeEmoji)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image("yes-emoji")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                            )
                    }
                }
                .padding(.leading, 15)
            }

            Spacer()

            VStack(alignment: .leading) {
                Text("Hashtags?")
                    .headerStyle()
                    .padding(.vertical)

                HStack(spacing: 15) {
                    Button {
                        Haptics.shared.play(.soft)
                        includeHashtag = false
                    } label: {
                        RectangleCard(title: "", description: nil, isSelected: !includeHashtag)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image("no-hashtag")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                            )
                    }

                    Button {
                        Haptics.shared.play(.soft)
                        includeHashtag = true
                    } label: {
                        RectangleCard(title: "", description: nil, isSelected: includeHashtag)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image("yes-hashtag")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                            )
                    }
                }
                .padding(.trailing, 15)
            }
        }
    }
}

struct LengthSelectionSection: View {
    @State var sliderValues: [Int] = [0, 1, 2, 3, 4, 5]
    @State var selectedValue: Int = 0
    @Binding var lengthValue: String
    @Binding var captionLengthType: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("How lengthy should your caption be?")
                .headerStyle()
                .padding()

            Text("\(captionLengths[selectedValue].title)")
                .foregroundColor(Color.ui.cultured)
                .font(Font.ui.bodyLarge)
                .padding(.leading, 15)
                .offset(y: -10)

            SnappableSliderView(values: $sliderValues) { value in
                self.selectedValue = Int(value)
                self.lengthValue = captionLengths[Int(value)].value
                self.captionLengthType = captionLengths[Int(value)].type
                Haptics.shared.play(.soft)
            }
            .overlay(
                GeometryReader { geo in
                    let numberOfRidges = CGFloat(sliderValues.count - 1)
                    let xPosRidge = CGFloat(geo.size.width / numberOfRidges)

                    ForEach(Array(sliderValues.enumerated()), id: \.offset) { index, element in

                        if element != selectedValue {
                            Rectangle()
                                .fill(Color.ui.cultured)
                                .frame(width: 3, height: 20)
                                .position(x: CGFloat(xPosRidge * CGFloat(index)), y: 15)
                        }
                    }
                }
            )
            .padding(.trailing, 15)
            .padding(.leading, 15)
        }
        .onAppear {
            self.selectedValue = sliderValues[0]
            self.lengthValue = captionLengths[0].value
            self.captionLengthType = captionLengths[0].type
        }
    }
}
