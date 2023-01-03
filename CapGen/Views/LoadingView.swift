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
    @State var rotationDegreeS2 = initialDegree
    @State var rotationDegreeS3 = initialDegree
    
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
        }
        
        .onAppear() {
            Timer.scheduledTimer(withTimeInterval: animationTime, repeats: true) { timer in
                self.animateSpinner()
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
