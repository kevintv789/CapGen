//
//  SavedCaptionsView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/13/23.
//

import SwiftUI

struct SavedCaptionsView: View {
    @EnvironmentObject var firestore: FirestoreManager
    @State var hasCaptions: Bool = false
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            VStack {
                if (!hasCaptions) {
                    EmptyCaptionsView()
                } else {
                    PopulatedCaptionsView()
                }
                
                Spacer()
            }
        }
        .onAppear() {
            guard let userId = AuthManager.shared.userManager.user?.id as? String else { return }
            self.firestore.hasCaptions(for: userId) { captionsGroup in
                self.hasCaptions = captionsGroup != nil
            }
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
            
            LottieView(name: "space_man_empty", loopMode: .loop, isAnimating: true)
                .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT / 2)
            
            Text("Where did it all go?\n A vast emptiness looms...")
                .foregroundColor(.ui.richBlack)
                .font(.ui.title3)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .lineSpacing(7)
        }
    }
}
