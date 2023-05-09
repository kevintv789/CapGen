//
//  CustomToggleView.swift
//  CapGen
//
//  Created by Kevin Vu on 5/9/23.
//

import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    var activeImageName: String = "circle-check-purple"
    var inactiveImageName: String = "circle-x-red"
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .foregroundColor(configuration.isOn ? .ui.middleBluePurple : .ui.darkSalmon)
            
            HStack {
                Image(configuration.isOn ? "visible" : "not-visible")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .padding(.leading, 15)
                    .padding(.trailing, 10)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Persist your images")
                        .foregroundColor(.ui.cultured)
                        .font(.ui.headline)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text("Your images, your control")
                        .foregroundColor(.ui.cultured)
                        .font(.ui.headlineRegular)
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.ui.cultured)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .padding(3)
                            .overlay(
                                Image(configuration.isOn ? activeImageName : inactiveImageName)
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            )
                            .offset(x: configuration.isOn ? 15 : -15)
                    )
                    .frame(width: 70, height: 37)
                    .padding(.trailing)
            }
        }
        
        .frame(maxWidth: SCREEN_WIDTH * 0.9, maxHeight: SCREEN_HEIGHT * 0.15)
        .onTapGesture {
            withAnimation(.spring()) {
                configuration.isOn.toggle()
            }
        }
        
    }
}

struct CustomToggleView: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        Toggle(isOn: $isEnabled) {
            RoundedRectangle(cornerRadius: 12)
        }.toggleStyle(CustomToggleStyle())
    }
}

struct CustomToggleView_Previews: PreviewProvider {
    static var previews: some View {
        @State var isEnabled: Bool = false
        CustomToggleView(isEnabled: $isEnabled)
    }
}
