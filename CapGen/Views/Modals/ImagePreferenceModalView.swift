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
                    
                    Text("Activate this feature to safely archive your images with their corresponding captions. Each paired image and caption becomes a preserved memory, accessible solely by you.\n\nThe original image stands ready for you to revisit the inspiration behind each saved caption.These securely stored images are under your control, delete them at will within the app, no obligations attached.")
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
