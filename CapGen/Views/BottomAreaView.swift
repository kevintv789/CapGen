//
//  BottomAreaView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import SwiftUI

let MIN_HEIGHT: CGFloat = SCREEN_HEIGHT * 0.2
let MAX_HEIGHT: CGFloat = SCREEN_HEIGHT * 0.7

extension View {
    func dropInAndOutAnimation(value: Bool) -> some View {
        self.animation(.easeInOut(duration: 0.35), value: value)
    }
}

extension Text {
    func headerStyle() -> some View {
        self
            .foregroundColor(.ui.cultured)
            .font(.ui.graphikBold)
            .padding()
    }
}

struct BottomAreaView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var rewardedAd: GoogleRewardedAds
    @Binding var expandArea: Bool
    @Binding var platformSelected: String
    @Binding var promptText: String
    @Binding var credits: Int
    
    @State var lengthValue: String = ""
    @State var toneSelected: String = tones[0].title
    @State var includeEmojis: Bool = false
    @State var includeHashtags: Bool = false
    
    @State var displayLoadView: Bool = false
    
    @State var promptRequestStr: AIRequest?
    
    @State var showCaptionView: Bool = false
    @State var showProfileView: Bool = false
    @State var showCreditsDepletedBottomSheet: Bool = false
    
    @State var isAdDone: Bool = false
    
    func mapAllRequests() {
        promptRequestStr = AIRequest(platform: self.platformSelected, prompt: self.promptText, tone: self.toneSelected, includeEmojis: self.includeEmojis, includeHashtags: self.includeHashtags, captionLength: self.lengthValue)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.richBlack
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .overlay(
                    ZStack {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 20) {
                                ToneSelectionSection(toneSelected: $toneSelected)
                                    .dropInAndOutAnimation(value: expandArea)
                                
                                EmojisAndHashtagSection(includeEmoji: $includeEmojis, includeHashtag: $includeHashtags)
                                    .dropInAndOutAnimation(value: expandArea)
                                
                                LengthSelectionSection(lengthValue: $lengthValue)
                                    .dropInAndOutAnimation(value: expandArea)
                                
                                Button {
                                    guard let userManager = AuthManager.shared.userManager.user else { return }
                                    mapAllRequests()
                                    
                                    if (credits < 1) {
                                        // Only show the bottom sheet modal if user has not selected 'Just play ad next time'
                                        if (userManager.userPrefs.showCreditDepletedModal) {
                                            self.showCreditsDepletedBottomSheet = true
                                        } else {
                                            // play ad and display load view
                                            self.isAdDone = self.rewardedAd.showAd(rewardFunction: {
                                                firestoreMan.incrementCredit(for: userManager.id)
                                            })
                                        }
                                    }
                                    else {
                                        displayLoadView.toggle()
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
                        
                        if (!expandArea) {
                            TabButtonsView(showCaptionView: $showCaptionView, showProfileView: $showProfileView)
                                .padding(.bottom, SCREEN_HEIGHT < 700 ? 50 : 80)
                        }
                    }
                )
                .frame(height: expandArea ? MAX_HEIGHT : MIN_HEIGHT)
                .offset(x: 0, y: expandArea ? 50 : MIN_HEIGHT / 1.2)
        }
        .navigationDestination(isPresented: $displayLoadView) {
            LoadingView(spinnerStart: 0.0, spinnerEndS1: 0.03, spinnerEndS2S3: 0.03, rotationDegreeS1: .degrees(270), rotationDegreeS2: .degrees(270), rotationDegreeS3: .degrees(270), promptRequestStr: $promptRequestStr)
                .navigationBarBackButtonHidden(true)
        }
        .navigationDestination(isPresented: $showCaptionView) {
            SavedCaptionsView()
                .navigationBarBackButtonHidden(true)
        }
        .navigationDestination(isPresented: $showProfileView) {
            ProfileView(isPresented: $showProfileView)
                .navigationBarBackButtonHidden(true)
        }
        .sheet(isPresented: $showCreditsDepletedBottomSheet) {
            CreditsDepletedModalView(isViewPresented: $showCreditsDepletedBottomSheet, displayLoadView: $displayLoadView)
                .presentationDetents([.fraction(SCREEN_HEIGHT < 700 ? 0.75 : 0.5)])
        }
        .onAppear() {
            self.expandArea = false
            
            // Once ad is done playing, display load view
            if (self.isAdDone) {
                self.displayLoadView = true
            }
        }
        .ignoresSafeArea(.all)
    }
}

struct TabButtonsView: View {
    @Binding var showCaptionView: Bool
    @Binding var showProfileView: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            Button {
                showCaptionView = true
            } label: {
                Image("hashtag-tab-icon")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
                .frame(width: SCREEN_WIDTH / 2)
            
            
            Button {
                showProfileView = true
            } label: {
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.ui.cultured)
            }
        }
    }
}

struct ExpandButton: View {
    @Binding var expandArea: Bool
    @State var showText: Bool = false
    
    var body: some View {
        Button {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 300)) {
                expandArea.toggle()
            }
        } label: {
            Circle()
                .strokeBorder(Color.ui.lighterLavBlue, lineWidth: 4)
                .background(
                    Circle()
                        .foregroundColor(Color.ui.richBlack)
                )
                .overlay(
                    VStack(spacing: 3) {
                        Image("chevron-up-white")
                            .resizable()
                            .frame(width: expandArea ? 40 : 30, height: expandArea ? 40 : 30)
                            .rotationEffect(.degrees(expandArea ? -180 : 0))
                        
                        
                        if (showText) {
                            Text("Next")
                                .foregroundColor(.ui.cultured)
                                .font(.ui.graphikBoldMed)
                        }
                        
                    }
                        .offset(y: expandArea ? 0 : -5)
                    
                )
                .frame(width: 80, height: 80)
            
        }
        .animation(.interpolatingSpring(stiffness: 200, damping: 300), value: expandArea)
        .onAppear() {
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                withAnimation {
                    self.showText = !expandArea
                }
            }
        }
    }
}

struct ToneSelectionSection: View {
    @Binding var toneSelected: String
    
    func toneSelect(tone: ToneModel) {
        toneSelected = tone.title
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Choose the tone")
                .headerStyle()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(tones) { tone in
                        Button {
                            toneSelect(tone: tone)
                        } label: {
                            RectangleCard(title: tone.title, description: tone.description, isSelected: toneSelected == tone.title)
                                .frame(width: 110, height: 110)
                        }
                        .padding(.leading, 15)
                    }
                }
            }
            
            .frame(height: 120)
        }
    }
}

struct EmojisAndHashtagSection: View {
    @Binding var includeEmoji: Bool
    @Binding var includeHashtag: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Include emojis and hashtags?")
                .headerStyle()
            
            HStack {
                HStack(spacing: 15) {
                    Button {
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
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button {
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
                        includeHashtag = true
                    } label: {
                        RectangleCard(title: "", description: nil, isSelected: includeHashtag)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "number.circle.fill")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .foregroundColor(.ui.richBlack)
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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("How lengthy should your caption be?")
                .headerStyle()
            
            Text("\(captionLengths[selectedValue].title)")
                .foregroundColor(Color.ui.cultured)
                .font(Font.ui.graphikLightItalic)
                .padding(.leading, 15)
                .offset(y: -10)
            
            SnappableSliderView(values: $sliderValues) { value in
                self.selectedValue = Int(value)
                self.lengthValue = captionLengths[Int(value)].value
            }
            .overlay(
                GeometryReader { geo in
                    let numberOfRidges = CGFloat(sliderValues.count - 1)
                    let xPosRidge = CGFloat(geo.size.width / numberOfRidges)
                    
                    ForEach(Array(sliderValues.enumerated()), id: \.offset) { index, element in
                        
                        if (element != selectedValue) {
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
        .onAppear() {
            self.selectedValue = sliderValues[0]
            self.lengthValue = captionLengths[0].value
        }
    }
}
