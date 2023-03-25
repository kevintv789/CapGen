//
//  PersonalizeOptionsView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import NavigationStack
import SwiftUI

struct PersonalizeOptionsView: View {
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel
    @EnvironmentObject var navStack: NavigationStackCompat

    @State var selectedSection: Int? = 0
    @State var isTonesSectionSelected: Bool = true
    @State var isEmojisAndHashtagsViewSelected: Bool = false
    @State var isChooseLengthViewSelected: Bool = false

    var body: some View {
        ZStack {
            Color.ui.lightOldPaper.ignoresSafeArea()

            VStack(alignment: .center) {
                // header
                GenerateCaptionsHeaderView(title: "Tailor your captions", isOptional: true, isNextSubmit: true) {
                    // on click next
                    self.navStack.push(LoadingView())
                }

                // Accordion
                ScrollViewReader { scrollProxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .center, spacing: 20) {
                            TonesSelectionView(isSelected: $isTonesSectionSelected)
                                .id("tones")
                            EmojisAndHashtagsView(isSelected: $isEmojisAndHashtagsViewSelected)
                                .id("emojisAndHashtags")
                            ChooseLengthView(isSelected: $isChooseLengthViewSelected)
                                .id("length")
                        }
                        .padding()
                    }
                    .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT * 0.8)
                    
                    // automatically scroll to the selected option
                    .onChange(of: isTonesSectionSelected) { _ in
                        withAnimation {
                            scrollProxy.scrollTo("tones", anchor: .top)
                        }
                    }
                    .onChange(of: isEmojisAndHashtagsViewSelected) { _ in
                        withAnimation {
                            scrollProxy.scrollTo("emojisAndHashtags", anchor: .top)
                        }
                    }
                    .onChange(of: isChooseLengthViewSelected) { _ in
                        withAnimation {
                            scrollProxy.scrollTo("length", anchor: .top)
                        }
                    }
                }
               

                .padding(.top)

                Spacer()
            }
        }
    }
}

struct PersonalizeOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalizeOptionsView()
            .environmentObject(GenerateByPromptViewModel())
            .environmentObject(NavigationStackCompat())

        PersonalizeOptionsView()
            .environmentObject(GenerateByPromptViewModel())
            .environmentObject(NavigationStackCompat())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct TonesSelectionView: View {
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel
    let columns = [
        GridItem(.flexible(minimum: 10), spacing: 20),
        GridItem(.flexible(minimum: 10), spacing: 20),
        GridItem(.flexible(minimum: 10), spacing: 20),
    ]

    @Binding var isSelected: Bool

    var body: some View {
        VStack {
            AccordionSectionView(title: "Choose up to 2 tones", isSelected: $isSelected)

            // Content
            Image("idea_robot")
                .resizable()
                .frame(width: SCREEN_WIDTH / 1.7, height: isSelected ? 260 : 0)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(tones) { tone in
                    Button {
                        Haptics.shared.play(.soft)

                        // Don't select the same tone again
                        if !self.genPromptVm.selectdTones.contains(tone) {
                            self.genPromptVm.selectdTones.append(tone)
                        } else {
                            // If an already existing item is selected, then remove
                            self.genPromptVm.selectdTones = genPromptVm.selectdTones.filter { $0 != tone }
                        }

                        // Remove first selected item to keep it at a maximum of 2 selections
                        if genPromptVm.selectdTones.count > 2 {
                            genPromptVm.selectdTones.remove(at: 0)
                        }
                    } label: {
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .stroke(genPromptVm.selectdTones.contains(tone) ? Color.ui.cultured : Color.ui.cadetBlueCrayola, lineWidth: genPromptVm.selectdTones.contains(tone) ? 10 : 1)
                                    .if(genPromptVm.selectdTones.contains(tone)) { view in
                                        view.shadow(color: Color.ui.richBlack.opacity(0.5), radius: 4, x: 0, y: 2)
                                    }

                                Circle()
                                    .fill(genPromptVm.selectdTones.contains(tone) ? Color.ui.middleBluePurple : Color.ui.cultured)
                                    .overlay(
                                        VStack(spacing: 15) {
                                            Text(tone.icon)
                                                .font(.ui.largeTitle)
                                        }
                                    )
                            }
                            .frame(width: isSelected ? 85 : 0, height: isSelected ? 85 : 0)

                            Text(tone.title)
                                .foregroundColor(genPromptVm.selectdTones.contains(tone) ? .ui.darkerPurple : .ui.richBlack.opacity(0.5))
                                .font(.ui.headline)
                        }
                    }
                }
            }
            .opacity(isSelected ? 1 : 0)
            .frame(maxHeight: isSelected ? .infinity : 0)
        }
    }
}

struct EmojisAndHashtagsView: View {
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel
    @Binding var isSelected: Bool

    var body: some View {
        VStack {
            AccordionSectionView(title: "Include emojis & hashtags?", isSelected: $isSelected)

            Image("emoji_robot")
                .resizable()
                .frame(width: SCREEN_WIDTH / 1.7, height: isSelected ? 260 : 0)

            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Emojis?")
                        .font(.ui.headline)
                        .foregroundColor(.ui.middleBluePurple)

                    HStack(spacing: 20) {
                        CircularButtonView(isSelected: !$genPromptVm.includeEmojis, imageName: "no-emoji", size: 65) {
                            genPromptVm.includeEmojis = false
                        }

                        CircularButtonView(isSelected: $genPromptVm.includeEmojis, imageName: "yes-emoji", size: 65) {
                            genPromptVm.includeEmojis = true
                        }
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Hashtags?")
                        .font(.ui.headline)
                        .foregroundColor(.ui.middleBluePurple)

                    HStack(spacing: 20) {
                        CircularButtonView(isSelected: !$genPromptVm.includeHashtags, imageName: "no-hashtag", size: 65) {
                            genPromptVm.includeHashtags = false
                        }

                        CircularButtonView(isSelected: $genPromptVm.includeHashtags, imageName: "yes-hashtag", size: 65) {
                            genPromptVm.includeHashtags = true
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .opacity(isSelected ? 1 : 0)
            .frame(maxHeight: isSelected ? .infinity : 0)
        }
    }
}

struct ChooseLengthView: View {
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel
    @Binding var isSelected: Bool

    @State var sliderValues: [Int] = [0, 1, 2, 3, 4, 5]

    var body: some View {
        VStack {
            AccordionSectionView(title: "Choose the length", isSelected: $isSelected)

            Image("ruler_robot")
                .resizable()
                .frame(width: SCREEN_WIDTH / 1.7, height: isSelected ? 260 : 0)

            VStack(alignment: .leading) {
                Text("\(captionLengths[self.genPromptVm.captionLengthId].title)")
                    .foregroundColor(Color.ui.middleBluePurple)
                    .font(.ui.headline)
                    .padding(.leading, 15)
                    .offset(y: -10)

                SnappableSliderView(values: $sliderValues, selectedValue: $genPromptVm.captionLengthId) { value in
                    self.genPromptVm.captionLengthId = Int(value)
                    self.genPromptVm.captionLengthValue = captionLengths[Int(value)].value
                    self.genPromptVm.captionLengthType = captionLengths[Int(value)].type
                    Haptics.shared.play(.soft)
                }
                .overlay(
                    GeometryReader { geo in
                        let numberOfRidges = CGFloat(sliderValues.count - 1)
                        let xPosRidge = CGFloat(geo.size.width / numberOfRidges)

                        ForEach(Array(sliderValues.enumerated()), id: \.offset) { index, element in

                            if element != self.genPromptVm.captionLengthId {
                                Rectangle()
                                    .fill(Color.ui.darkerPurple) // tick color
                                    .frame(width: 3, height: 20)
                                    .position(x: CGFloat(xPosRidge * CGFloat(index)), y: 15)
                            }
                        }
                    }
                )
                .padding(.trailing, 15)
                .padding(.leading, 15)
            }
            .opacity(isSelected ? 1 : 0)
            .frame(maxHeight: isSelected ? .infinity : 0)
        }
    }
}

struct CircularButtonView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    @Binding var isSelected: Bool
    var imageName: String
    var size: CGFloat = 85
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.play(.soft)
            action()
        } label: {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.ui.cultured : Color.ui.cadetBlueCrayola, lineWidth: isSelected ? 10 : 1)
                    .if(isSelected) { view in
                        view.shadow(color: Color.ui.richBlack.opacity(0.5), radius: 4, x: 0, y: 2)
                    }

                Circle()
                    .fill(isSelected ? Color.ui.middleBluePurple : Color.ui.cultured)

                Image(imageName)
                    .resizable()
                    .frame(width: 40 * scaledSize, height: 40 * scaledSize)
            }
            .frame(width: size * scaledSize, height: size * scaledSize)
        }
    }
}

struct AccordionSectionView: View {
    let title: String
    @Binding var isSelected: Bool

    var body: some View {
        Button {
            withAnimation {
                Haptics.shared.play(.soft)
                self.isSelected.toggle()
            }
        } label: {
            ZStack {
                if self.isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ui.cultured, lineWidth: 10)
                        .shadow(color: Color.ui.richBlack.opacity(0.5), radius: 4, x: 0, y: 2)
                }

                RoundedRectangle(cornerRadius: 16)
                    .fill(self.isSelected ? Color.ui.middleBluePurple : Color.ui.cadetBlueCrayola)

                    .overlay(
                        HStack {
                            Text(title)
                                .font(.ui.headline)
                                .foregroundColor(.ui.cultured)

                            Spacer()

                            Image("down-chevron")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .rotationEffect(.degrees(self.isSelected ? 180 : 0))
                        }.padding(.horizontal)
                    )
            }
            .frame(height: 50)
        }
    }
}
