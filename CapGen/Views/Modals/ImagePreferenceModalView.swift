//
//  ImagePreferenceModalView.swift
//  CapGen
//
//  Created by Kevin Vu on 5/9/23.
//

import SwiftUI

struct ImagePreferenceModalView: View {
    @EnvironmentObject var userPrefsVm: UserPreferencesViewModel
    @EnvironmentObject var firestoreMan: FirestoreManager
    
    let userManager = AuthManager.shared.userManager
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center) {
                    // title
                    Text("Image Storage Preferences")
                        .foregroundColor(.ui.richBlack.opacity(0.5))
                        .font(.ui.title4)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.top, 20)
                    
                    Image("cloud_robot")
                        .resizable()
                        .frame(width: 270, height: 270)
                    
                    CustomToggleView(isEnabled: $userPrefsVm.persistImage)
                        .frame(height: 100)
                        .onChange(of: userPrefsVm.persistImage) { value in
                            firestoreMan.setPersistImagePreference(for: userManager.user?.id ?? nil, to: value)
                        }
                    
                    Text("Turn on 'Persist your images', and every snap you pair with a caption becomes more than just a fleeting moment - it's safely stored for your eyes only 👀.\n\nSo the next time you want to relive the memory or inspiration behind a saved caption, the original image will be right there with it.\n\nThese images aren't just securely stored, they're yours to command 💪. Delete them whenever you want, right within the app - no strings attached 🎈.\n\nAnd the best part? You're always in control. This feature is totally optional. Want to keep your images private? Just flip the toggle. It's your images, your app, your control 👑.")
                        .multilineTextAlignment(.leading)
                        .font(.ui.title5)
                        .foregroundColor(.ui.richBlack.opacity(0.5))
                        .frame(maxWidth: SCREEN_WIDTH * 0.85)
                        .lineSpacing(8)
                        .padding(.top)
                }
            }
        }
    }
}

struct ImagePreferenceModalView_Previews: PreviewProvider {
    static var previews: some View {
        ImagePreferenceModalView()
            .environmentObject(UserPreferencesViewModel())
        
        ImagePreferenceModalView()
            .environmentObject(UserPreferencesViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
