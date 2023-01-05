//
//  LoadingView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import SwiftUI

struct LoadingView: View {
    let rotationTime: Double = 0.75 // seconds to complete a full rotation
    let animationTime: Double = 1.9
    
    let fullRotation: Angle = .degrees(360)
    static let initialDegree: Angle = .degrees(270)
    
    @State var spinnerStart: CGFloat = 0.0
    @State var spinnerEndS1: CGFloat = 0.03
    @State var spinnerEndS2S3: CGFloat = 0.03
    @State var rotationDegreeS1 = initialDegree
    @State var rotationDegreeS2: Angle = initialDegree
    @State var rotationDegreeS3: Angle = initialDegree
    
    @State var showCaptionView: Bool = false
    
    @State var openAiResponse: String?
    
    private var openAiRequest = OpenAIConnector()
    
    func animateSpinner(with timeInterval: Double, completion: @escaping (() -> Void)) {
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            withAnimation(Animation.easeInOut(duration: rotationTime)) {
                completion()
            }
        }
    }
    
    func animateSpinner() {
        animateSpinner(with: rotationTime) {
            self.spinnerEndS1 = 1.0
        }
        
        animateSpinner(with: (rotationTime * 2) - 0.025) {
            self.rotationDegreeS1 += fullRotation
            self.spinnerEndS2S3 = 0.8
        }
        
        animateSpinner(with: rotationTime * 2) {
            self.spinnerEndS1 = 0.03
            self.spinnerEndS2S3 = 0.03
        }
        
        animateSpinner(with: (rotationTime * 2) + 0.0725) {
            self.rotationDegreeS2 += fullRotation
        }
        
        animateSpinner(with: (rotationTime * 2) + 0.225) {
            self.rotationDegreeS3 += fullRotation
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.ui.richBlack.ignoresSafeArea(.all)
                    .overlay(
                        ZStack {
                            // S3
                            SpinnerCircle(start: spinnerStart, end: spinnerEndS2S3, rotation: rotationDegreeS3, color: .ui.middleBluePurple)
                            
                            // S2
                            SpinnerCircle(start: spinnerStart, end: spinnerEndS2S3, rotation: rotationDegreeS2, color: .ui.darkSalmon)
                            
                            // S1
                            SpinnerCircle(start: spinnerStart, end: spinnerEndS1, rotation: rotationDegreeS1, color: .ui.lighterLavBlue)
                            
                            Text("Generating captions, please wait.")
                                .foregroundColor(.ui.cultured)
                                .font(.ui.graphikMediumMed)
                        }.frame(width: geo.size.width * 0.8, height: geo.size.height * 0.8)
                    )
            }
            .onAppear() {
                self.animateSpinner()
                
                Timer.scheduledTimer(withTimeInterval: animationTime, repeats: true) { _ in
                    self.animateSpinner()
                }
                
                Task {
                    openAiResponse = await openAiRequest.processPrompt(prompt: "Generate 5 captions for a photo of my dog playing in the park. She's a rescue and brings so much joy to my life. Please come up with a caption that celebrates the love and happiness that pets bring into our lives. This should have a minimum of 21 words and a max of 40 words, the word count should be excluding emojis. Use emojis. This is for an YouTube caption only.")
                    
                    print(openAiResponse ?? "nil")
                    
                    if (openAiResponse != nil && !openAiResponse!.isEmpty) {
                        showCaptionView = true
                    }
                }
            }
            .navigationDestination(isPresented: $showCaptionView) {
                CaptionView(captionStr: $openAiResponse)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
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
