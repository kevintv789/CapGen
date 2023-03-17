//
//  DropdownMenu.swift
//  CapGen
//
//  Created by Kevin Vu on 3/7/23.
//

import SwiftUI

struct DropdownOptions: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String = ""
    var imageName: String = ""
    var isCircularImage: Bool = false
}

struct DropdownMenu: View {
    var title: String
    var socialMediaIcon: String?

    @Binding var isMenuOpen: Bool

    var body: some View {
        ZStack {
            Button {
                Haptics.shared.play(.soft)
                withAnimation {
                    self.isMenuOpen.toggle()
                }

            } label: {
                HStack {
                    if socialMediaIcon != nil {
                        Image("\(socialMediaIcon!)-circle")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .scaledToFit()
                            .padding(3)
                            .background(
                                Circle()
                                    .fill(Color.ui.cultured)
                            )
                    }

                    Text(title)
                        .font(.ui.headline)
                        .foregroundColor(.ui.cultured)
                        .fixedSize(horizontal: true, vertical: false)

                    Image("down-chevron-white-plain")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(self.isMenuOpen ? 180 : 0))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.ui.richBlack.opacity(0.8))
            )
        }
    }
}

struct DropdownMenuList: View {
    var options: [DropdownOptions]
    var selectedOption: DropdownOptions
    var action: (_ title: String) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.ui.lighterBlack.ignoresSafeArea(.all)

            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(options) { option in
                            Button {
                                Haptics.shared.play(.soft)
                                action(option.title)
                            } label: {
                                HStack(spacing: 15) {
                                    if !option.imageName.isEmpty {
                                        Image(option.imageName)
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .scaledToFit()
                                            .padding(3)
                                            .if(option.isCircularImage, transform: { view in
                                                view
                                                    .background(
                                                        Circle()
                                                            .fill(Color.ui.cultured)
                                                    )
                                            })
                                    }

                                    Text(option.title)
                                        .font(.ui.title4Medium)
                                        .foregroundColor(.ui.cultured)
                                }
                                .frame(width: SCREEN_WIDTH * 0.85, alignment: .leading)
                            }
                            .id(option.title)
                            .if(selectedOption.title == option.title) { view in
                                view
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.ui.cadetBlueCrayola.opacity(0.15))
                                    )
                            }
                        }
                    }
                }
                .onAppear {
                    withAnimation {
                        scrollProxy.scrollTo(selectedOption.title, anchor: .center)
                    }
                }
            }
            .padding(20)
        }
        .cornerRadius(14, corners: .allCorners)
        .frame(minWidth: SCREEN_WIDTH * 0.9, minHeight: SCREEN_HEIGHT / 3)
        .offset(x: 12)
    }
}
