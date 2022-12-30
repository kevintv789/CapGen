//
//  BottomAreaView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import SwiftUI

let MIN_HEIGHT: CGFloat = 350.0

struct BottomAreaView: View {
    @State private var expandArea: Bool = false
    @Binding var toneSelected: String
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.ui.richBlack
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .frame(height: max(MIN_HEIGHT, expandArea ? UIScreen.main.bounds.height : geo.size.height / 1.1))
                    .position(x: geo.size.width / 2, y: geo.size.height / 1.8)
                
                VStack {
                    ExpandButton(expandArea: $expandArea)
                        .offset(x: geo.size.width / 2.3, y: expandArea ? -geo.size.height / 1.7 : geo.size.height / 9)
                    
                    ToneSelectionSection(toneSelected: $toneSelected)
                        .offset(x: 0, y: expandArea ? -geo.size.height / 1.7 : geo.size.height / 12)
                    
                    Spacer()
                }
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
                .foregroundColor(.ui.cultured)
                .font(.ui.graphikBold)
                .padding()
            
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
