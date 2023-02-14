//
//  ContentView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/27/22.
//

import Firebase
import FirebaseAuth
import NavigationStack
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    let navigationStack: NavigationStackCompat
    @State var router: Router?

    var body: some View {
        NavigationStackView(navigationStack: navigationStack) {
            EmptyView() // Maybe a loading screen here instead?
        }
        .onReceive(authManager.$isSignedIn) { isLoggedIn in
            // Push to initial screen
            self.router = Router(navStack: navigationStack, isLoggedIn: isLoggedIn ?? false)
        }
        .onReceive(authManager.$appError) { value in
            if let error = value?.error {
                if error == .loginError {
                    self.router?.toLoginFallbackView()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(navigationStack: NavigationStackCompat())
            .previewDevice("iPhone 14 Pro Max")
            .previewDisplayName("iPhone 14 Pro Max")

        ContentView(navigationStack: NavigationStackCompat())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
