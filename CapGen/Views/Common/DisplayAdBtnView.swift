//
//  DisplayAdBtnView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/18/23.
//

import Heap
import NavigationStack
import SwiftUI

enum ButtonLength {
    case short, full
}

struct DisplayAdBtnView: View {
    @ObservedObject var ad = AppodealProvider.shared
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat

    @State var router: Router? = nil

    @State var btnLength: ButtonLength = .full
    let authManager = AuthManager.shared.userManager

    @State var title: String

    var body: some View {
        FullscreenSection(
            text: title,
            ad: self.ad,
            keyPath: \.isRewardedReady,
            btnLength: btnLength
        ) {
            Heap.track("onClick DisplayAdBtnView - Show Ad")
            Haptics.shared.play(.soft)
            self.ad.presentRewarded()
        }
        .onAppear {
            self.router = Router(navStack: navStack)
        }
        .onReceive(self.ad.$appError) { value in
            if let error = value?.error {
                if error == .genericError {
                    self.router?.toGenericFallbackView()
                }
            }
        }
    }
}

struct FullscreenSection<T>: View where T: ObservableObject {
    typealias Action = () -> Void
    let text: String
    @ObservedObject var ad: T
    var keyPath: ReferenceWritableKeyPath<T, Bool>
    var btnLength: ButtonLength = .full
    var action: Action

    func displayBtnOverlay() -> some View {
        // if is loading
        if !ad[keyPath: keyPath] {
            return AnyView(
                LottieView(name: "btn_loader", loopMode: .loop, isAnimating: true)
                    .frame(width: 100, height: 100)
            )
        } else {
            return AnyView(
                Text(text)
                    .foregroundColor(.ui.cultured)
                    .font(.ui.title2)
            )
        }
    }

    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.orangeWeb)
                .frame(width: btnLength == .full ? SCREEN_WIDTH / 1.2 : SCREEN_WIDTH / 1.4, height: 55)
                .frame(maxWidth: .infinity, alignment: .center)
                .overlay(displayBtnOverlay())
        }
        .disabled(!ad[keyPath: keyPath])
        .transition(.slide)
    }
}
