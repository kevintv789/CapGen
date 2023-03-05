//
//  BottomAreaView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import SwiftUI

let MIN_HEIGHT: CGFloat = 50.0
let MAX_HEIGHT: CGFloat = UIScreen.main.bounds.height * 1.5

extension View {
    func dropInAndOutAnimation(value: Bool) -> some View {
        animation(.easeInOut(duration: 0.35), value: value)
    }
}

extension Text {
    func headerStyle() -> some View {
        foregroundColor(.ui.cultured)
            .font(.ui.graphikBold)
            .padding()
    }
}

struct BottomAreaView: View {
    @Binding var expandArea: Bool
    @Binding var platformSelected: String
    @Binding var promptText: String

    @State var lengthValue: String = ""
    @State var toneSelected: String = tones[0].title
    @State var includeEmojis: Bool = false
    @State var includeHashtags: Bool = false

    @State var displayLoadView: Bool = false

    @State var promptRequestStr: AIRequest?

    func mapAllRequests() {
        promptRequestStr = AIRequest(platform: platformSelected, prompt: promptText, tone: toneSelected, includeEmojis: includeEmojis, includeHashtags: includeHashtags, captionLength: lengthValue)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.ui.richBlack
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .frame(height: max(MIN_HEIGHT, expandArea ? MAX_HEIGHT : geo.size.height / 3))
                    .position(x: geo.size.width / 2, y: geo.size.height)
                    .overlay(
                        VStack(alignment: .leading) {
                            ExpandButton(expandArea: $expandArea)
                                .offset(x: geo.size.width / 1.15, y: expandArea ? 0 : MIN_HEIGHT * 3.8)

                            ToneSelectionSection(toneSelected: $toneSelected)
                                .offset(x: 0, y: expandArea ? -20 : geo.size.height)
                                .dropInAndOutAnimation(value: expandArea)

                            EmojisAndHashtagSection(includeEmoji: $includeEmojis, includeHashtag: $includeHashtags)
                                .offset(x: 0, y: expandArea ? -20 : geo.size.height)
                                .dropInAndOutAnimation(value: expandArea)

                            LengthSelectionSection(lengthValue: $lengthValue)
                                .dropInAndOutAnimation(value: expandArea)

                            Button {
                                mapAllRequests()
                                displayLoadView.toggle()
                            } label: {
                                Image("submit-btn-1")
                                    .resizable()
                                    .frame(width: 90, height: 90)
                            }.offset(x: geo.size.width / 2.4, y: expandArea ? 20 : geo.size.height)
                        }
                        .offset(x: 0, y: expandArea ? -geo.size.height / 2.2 : geo.size.height / 1.67)
                        .frame(height: MAX_HEIGHT)
                    )
                    // Make the entire black area with minimal height tappable -- not just the button
                    .onTapGesture(perform: {
                        if !expandArea {
                            withAnimation {
                                expandArea.toggle()
                            }
                            .offset(x: 0, y: expandArea ? 0 : SCREEN_HEIGHT)
                            .padding(.top, 50)
                        }
                    })
            }
        }
        
        //        }
        .navigationDestination(isPresented: $displayLoadView) {
            LoadingView(spinnerStart: 0.0, spinnerEndS1: 0.03, spinnerEndS2S3: 0.03, rotationDegreeS1: .degrees(270), rotationDegreeS2: .degrees(270), rotationDegreeS3: .degrees(270), promptRequestStr: $promptRequestStr)
                .navigationBarBackButtonHidden(true)
        }
        .ignoresSafeArea(.all)
    }
}

struct ExpandButton: View {
    @Binding var expandArea: Bool
    var body: some View {
        Button {
            withAnimation() {
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
        .animation(.spring(), value: expandArea)
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
    @State var sliderValues: [Int] = [0, 1, 2, 3, 4]
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
            selectedValue = sliderValues[0]
        }
    }
}
