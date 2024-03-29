//
//  CaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import SwiftUI

struct CaptionView: View {
    @State var backBtnClicked: Bool = false
    @Binding var captionStr: String?
    @State var captionsParsed: [String] = []
    @State var captionSelected: String = ""
    @State var cardColorFill: [Color] = [.ui.middleYellowRed, .ui.darkSalmon, .ui.frenchBlueSky, .ui.lightCyan, .ui.middleBluePurple]

    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.lighterLavBlue.ignoresSafeArea()

            VStack(alignment: .leading) {
                Button {
                    backBtnClicked.toggle()
                } label: {
                    Image("back_arrow")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding(-30)
                        .padding(.leading, 15)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading) {
                        Text("Your results")
                            .font(.ui.graphikSemiboldLarge)
                            .foregroundColor(.ui.richBlack)

                        Spacer()

                        ForEach(Array(captionsParsed.enumerated()), id: \.element) { index, caption in
                            Button {
                                self.captionSelected = caption
                                UIPasteboard.general.string = String(caption.dropFirst(3))
                            } label: {
                                CaptionCard(caption: caption, isCaptionSelected: caption == captionSelected, colorFilled: $cardColorFill[index])
                                    .padding(10)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationDestination(isPresented: $backBtnClicked) {
            ContentView(platformSelected: SocialMediaPlatforms().platforms[0])
                .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            captionsParsed = captionStr?
                .components(separatedBy: "\n")
                .filter { element in
                    !element.isEmpty
                } ?? []
        }
    }
}

struct CaptionView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionView(captionStr: .constant("\n\n1. the love and hap 🤗"))
    }
}

struct CaptionCard: View {
    var caption: String
    var isCaptionSelected: Bool
    @State private var phase = 0.0
    @Binding var colorFilled: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorFilled)
                )

            VStack(alignment: .trailing, spacing: 0) {
                Text(caption.dropFirst(3))
                    .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                    .font(.ui.graphikRegular)
                    .lineSpacing(4)
                    .foregroundColor(.ui.richBlack)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isCaptionSelected {
                    Text("Copied!")
                        .foregroundColor(Color.ui.richBlack)
                        .font(.ui.graphikMediumMed)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        .frame(height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4], dashPhase: phase))
                                .foregroundColor(Color.ui.richBlack)
                                .onAppear {
                                    withAnimation(.linear.repeatForever(autoreverses: false).speed(0.1)) {
                                        phase += 20
                                    }
                                }
                        )
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 12))
                }
            }
        }
    }
}
