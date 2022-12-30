//
//  CapGenApp.swift
//  CapGen
//
//  Created by Kevin Vu on 12/27/22.
//

import SwiftUI

@main
struct CapGenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(platformSelected: SocialMediaPlatforms.init().platforms[0],
                        toneSelected: tones[0].title)
        }
    }
}
