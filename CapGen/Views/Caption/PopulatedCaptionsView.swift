//
//  PopulatedCaptionsView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/20/23.
//

import SwiftUI

extension View {
    func customCardStyle() -> some View {
        return self
            .frame(width: SCREEN_WIDTH * 0.9, height: SCREEN_HEIGHT / 4)
            .padding()
            .shadow(
                color: Color.ui.richBlack.opacity(0.5),
                radius: 2,
                x: 1,
                y: 2
            )
    }
}

struct PopulatedCaptionsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var firestore: FirestoreManager
    
    @State var isLoading: Bool = false
    @State var platformSelected: String = ""
    @State var filteredCaptionsGroup: [AIRequest] = []
    @State var platforms: [String] = []
    /**
     MOCKED VALUES BELOW
     */
    //    @State var platforms: [String] = ["Twitter", "Instagram", "Youtube"]
    //    @State var filteredCaptionsGroup: [AIRequest] = [AIRequest(id: "123", platform: "Instagram", prompt: "Generate me a caption about my two dogs playing in the sunny park in an open field of rainbows and sunshine and unicorn and sunshine and unicorn and sunshine and unicorn and sunshine andne and unicorn and sunshine and unicorn and sunshine andne and unicorn and sunshine and unicorn and sunshine and unicorn", tone: "Formal", includeEmojis: true, includeHashtags: false, captionLength: "veryShort", title: "Embrace Joy", dateCreated: "Jan 20, 3:11 PM", captions: [
    //
    //        GeneratedCaptions(description: "test1"),
    //        GeneratedCaptions(description: "test2"),
    //        GeneratedCaptions(description: "test3"),
    //        GeneratedCaptions(description: "test4"),
    //        GeneratedCaptions(description: "test5"),
    //    ])]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            if (isLoading) {
                ProgressView()
                    .foregroundColor(.ui.cadetBlueCrayola)
            } else {
                VStack {
                    Color.ui.lavenderBlue.ignoresSafeArea(.all)
                        .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT * 0.13)
                        .overlay(
                            VStack(spacing: 0) {
                                BackArrowView {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                                .frame(maxWidth: SCREEN_WIDTH, alignment: .leading)
                                .frame(height: 10)
                                .padding(.leading, 15)
                                .padding(.bottom, 20)
                                
                                PlatformHeaderView(platforms: platforms, platformSelected: $platformSelected)
                                
                                Spacer()
                            }
                        )
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(filteredCaptionsGroup) { element in
                                ZStack(alignment: .topLeading) {
                                    StackedCardsView()
                                    VStack(alignment: .leading, spacing: 20) {
                                        CardTitleHeaderView(title: element.title)
                                        
                                        Button {
                                            
                                        } label: {
                                            VStack(alignment: .leading) {
                                                Text(element.prompt)
                                                    .font(.ui.bodyLarge)
                                                    .foregroundColor(.ui.cultured)
                                                    .lineLimit(Int(SCREEN_HEIGHT / 180))
                                                    .multilineTextAlignment(.leading)
                                                    .lineSpacing(3)
                                                
                                                Spacer()
                                                
                                                HStack {
                                                    Image("Instagram")
                                                        .resizable()
                                                        .frame(width: 35, height: 35)
                                                    
                                                    Image("Instagram")
                                                        .resizable()
                                                        .frame(width: 35, height: 35)
                                                    
                                                    Spacer()
                                                    
                                                    Text(element.dateCreated)
                                                        .foregroundColor(.ui.cultured)
                                                        .font(.ui.headlineMd)
                                                    
                                                }
                                            }
                                        }
                                        
                                        
                                    }
                                    .padding(40)
                                }.id(element.title + element.id + element.dateCreated)
                            }
                        }
                       
                    }
                }
            }
        }
        .onReceive(AuthManager.shared.userManager.$user) { user in
            // This creates a set from an array of platforms by mapping the platform property of each object
            // Use this to retrieve all social media network platforms in an array
            
            if (user != nil) {
                let value = user!.captionsGroup
                let platformSet = Set(value.map { $0.platform })
                self.platforms = Array(platformSet)

                if (!self.platforms.isEmpty) {
                    self.platformSelected = self.platforms[0] // initiate the first item to be selected by default
                }
            }
            
        }
        .onChange(of: self.platformSelected) { value in
            // Filter to the selected social media network platform
            let captionsGroup = AuthManager.shared.userManager.user?.captionsGroup as? [AIRequest] ?? []
            self.filteredCaptionsGroup = captionsGroup.filter { $0.platform == value }
        }
    }
}

struct PopulatedCaptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PopulatedCaptionsView()
        
        PopulatedCaptionsView()
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct PlatformPillsBtnView: View {
    var title: String
    var isToggled: Bool
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 100)
                .fill(isToggled ? Color.ui.middleBluePurple : Color.ui.cultured)
                .shadow(
                    color: Color.ui.richBlack.opacity(isToggled ? 0 : 0.3),
                    radius: 2,
                    x: 1,
                    y: 2
                )
                .frame(width: SCREEN_WIDTH / 2.4, height: 40)
                .overlay(
                    HStack {
                        Image(title)
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        
                        Text(title)
                            .font(.ui.headline)
                            .foregroundColor(isToggled ? .ui.cultured : .ui.cadetBlueCrayola)
                    }
                    
                )
        }
    }
}

struct PlatformHeaderView: View {
    let platforms: [String]
    @Binding var platformSelected: String
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(platforms, id: \.self) { platform in
                        PlatformPillsBtnView(title: platform, isToggled: platformSelected == platform) {
                            self.platformSelected = platform
                        }
                        .id(platform)
                    }
                }
                .padding()
            }
            .onChange(of: self.platformSelected) { value in
                withAnimation {
                    scrollProxy.scrollTo(value, anchor: .center)
                }
            }
        }
    }
}

struct StackedCardsView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.darkSalmon)
                .offset(x: 10, y: 10)
                .customCardStyle()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.middleYellowRed)
                .offset(x: 5, y: 5)
                .customCardStyle()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.middleBluePurple)
                .customCardStyle()
        }
    }
}

struct CardTitleHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.ui.title)
                .foregroundColor(.ui.cultured)
                .scaledToFit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Spacer()
            
            // Edit button
            Button {
                print("Edit...")
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.ui.title)
                    .foregroundColor(.ui.cultured)
            }
        }
    }
}
