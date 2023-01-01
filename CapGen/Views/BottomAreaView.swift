//
//  BottomAreaView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import SwiftUI

let MIN_HEIGHT: CGFloat = 50.0
let MAX_HEIGHT: CGFloat = UIScreen.main.bounds.height * 1.2

extension View {
    func dropInAndOutAnimation(value: Bool) -> some View {
        self.animation(.easeInOut(duration: 0.4), value: value)
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
    @State private var expandArea: Bool = true
    @Binding var toneSelected: String
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.ui.richBlack
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .frame(height: max(MIN_HEIGHT, expandArea ? MAX_HEIGHT : geo.size.height / 3))
                    .position(x: geo.size.width / 2, y: geo.size.height)
                    .overlay(
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading) {
                                ExpandButton(expandArea: $expandArea)
                                    .offset(x: geo.size.width / 1.15, y: expandArea ? 10 : MIN_HEIGHT)
                                
                                ToneSelectionSection(toneSelected: $toneSelected)
                                    .offset(x: 0, y: expandArea ? 0 : geo.size.height)
                                    .dropInAndOutAnimation(value: expandArea)
                                
                                LengthSelectionSection()
                                    .dropInAndOutAnimation(value: expandArea)
                            }
                            .offset(x: 0, y: expandArea ? -geo.size.height / 1.8 : geo.size.height / 1.67)
                            .frame(height: MAX_HEIGHT)
                        }
                            .frame(width: geo.size.width, height: MAX_HEIGHT)
                    )
            }
        }
        .ignoresSafeArea(.all)
    }
}

struct ExpandButton: View {
    @Binding var expandArea: Bool
    
    var body: some View {
        Button {
            withAnimation {
                expandArea.toggle()
            }
        } label: {
            Image("chevron-up")
                .resizable()
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(expandArea ? -180 : 0))
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
                        }
                        .padding(.leading, 15)
                    }
                }
            }
            
            .frame(height: 120)
        }
        
    }
}

struct LengthSelectionSection: View {
    @State var sliderValues: [Int] = [1, 2, 3, 4, 5]
    @State var selectedValue: Int = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("How lengthy should your caption be?")
                .headerStyle()
            
            Text("")
                .foregroundColor(Color.ui.cultured)
                .font(Font.ui.graphikLightItalic)
                .padding(.leading, 15)
                .offset(y: -10)
            
            SnappableSliderView(values: $sliderValues) { value in
                self.selectedValue = Int(value)
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
            selectedValue = sliderValues[0]
        }
    }
}
