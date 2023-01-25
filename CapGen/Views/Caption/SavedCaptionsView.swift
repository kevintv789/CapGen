//
//  SavedCaptionsView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/13/23.
//

import SwiftUI

struct SavedCaptionsView: View {
    @State var hasCaptions: Bool = false
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            if (!hasCaptions) {
                EmptyCaptionsView()
            } else {
                PopulatedCaptionsView()
            }
        }
        .onAppear() {
            let captionsGroup = AuthManager.shared.userManager.user?.captionsGroup as? [AIRequest] ?? []
            self.hasCaptions = !captionsGroup.isEmpty
        }
    }
}

struct SavedCaptionsView_Previews: PreviewProvider {
    static var previews: some View {
        SavedCaptionsView()
    }
}

struct EmptyCaptionsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            BackArrowView {
                self.presentationMode.wrappedValue.dismiss()
            }
            .frame(maxWidth: SCREEN_WIDTH, alignment: .leading)
            .padding(.leading, 15)
            .padding(.top, 15)
            
            LottieView(name: "space_man_empty", loopMode: .loop, isAnimating: true)
                .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT / 2)
            
            Text("Where did it all go?\n A vast emptiness looms...")
                .foregroundColor(.ui.richBlack)
                .font(.ui.title3)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .lineSpacing(7)
            
            Spacer()
        }
    }
}
