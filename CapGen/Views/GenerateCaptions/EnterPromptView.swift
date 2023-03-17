//
//  EnterPromptView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import NavigationStack
import SwiftUI

struct EnterPromptView: View {
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel
    @EnvironmentObject var navStack: NavigationStackCompat

    // private variables
    @State var expandPromptArea: Bool = false
    @State var promptInput: String = ""
    @State var showEraseModal: Bool = false
    @State var imageOpacity: CGFloat = 1
    @State var initialTextOpacity: CGFloat = 1

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color.ui.lightOldPaper.ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                        Task {
                            await animate(duration: 0.25) {
                                Haptics.shared.play(.soft)
                                self.expandPromptArea = false
                                imageOpacity = 1
                                initialTextOpacity = 1
                            }
                        }
                    }

                VStack {
                    // header
                    GenerateCaptionsHeaderView(title: "Write your prompt") {
                        // on click next
                        self.navStack.push(PersonalizeOptionsView())
                    }

                    // cute robot illustration
                    Image("prompt_writing_robot")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .opacity(self.imageOpacity)

                    Spacer()

                    // Bottom typing area
                    PromptInputBottomView(isExpanded: self.$expandPromptArea, initialTextOpacity: $initialTextOpacity) {
                        // on erase
                        self.showEraseModal = true
                        Haptics.shared.play(.soft)
                    }
                    .frame(height: self.expandPromptArea ? SCREEN_HEIGHT / 1.2 : SCREEN_HEIGHT / (SCREEN_HEIGHT < 800 ? 2 : 3))

                    .onTapGesture {
                        Task {
                            await animate(duration: 0.25) {
                                Haptics.shared.play(.soft)
                                self.expandPromptArea = true

                                // Wait for animation to finish before showing views
                                imageOpacity = 0
                                initialTextOpacity = 0
                            }
                        }
                    }
                }
            }
        }

        // Show erase text modal
        .modalView(horizontalPadding: 50, show: $showEraseModal) {
            SimpleDeleteModal(showView: $showEraseModal) {
                // on delete
                genPromptVm.resetInput()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct EnterPromptView_Previews: PreviewProvider {
    static var previews: some View {
        EnterPromptView()
            .environmentObject(GenerateByPromptViewModel())

        EnterPromptView()
            .environmentObject(GenerateByPromptViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct GenerateCaptionsHeaderView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    let title: String
    var isOptional: Bool? = false
    var isNextSubmit: Bool? = false
    let nextAction: () -> Void

    var body: some View {
        // Header
        HStack {
            BackArrowView()

            Spacer()

            VStack(alignment: .center, spacing: 5) {
                Text(title)
                    .foregroundColor(.ui.richBlack.opacity(0.5))
                    .font(.ui.title4)
                    .fixedSize(horizontal: true, vertical: false)

                if isOptional ?? false {
                    Text("Optional")
                        .font(.ui.subheadlineLarge)
                        .foregroundColor(.ui.richBlack.opacity(0.5))
                }
            }
            .padding(.top, isOptional ?? false ? 15 : 0)

            Spacer()

            // next/submit button
            Button {
                nextAction()
            } label: {
                Image(isNextSubmit ?? false ? "play-button" : "next")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.bottom, 20)
        .padding(.horizontal)
    }
}

struct PromptInputBottomView: View {
    @EnvironmentObject var genPromptVm: GenerateByPromptViewModel

    let charLimit: Int = 500
    @State private var lastText: String = ""
    @FocusState var isFocused: Bool

    @Binding var isExpanded: Bool
    @Binding var initialTextOpacity: CGFloat
    var onErase: () -> Void

    var placeholderText: String = "Example: Please generate a caption for a photo of my dog playing in the park. She's a rescue and brings so much joy to my life. Please come up with a caption that celebrates the love and happiness that pets bring into our lives."

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.ui.richBlack
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .ignoresSafeArea()
                .overlay(
                    VStack(alignment: .leading) {
                        // show big text if collapsed
                        Text("begin\ntyping\nhere")
                            .font(.ui.largestTitle)
                            .foregroundColor(.ui.lighterLavBlue)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 40)
                            .padding(.horizontal)
                            .opacity(initialTextOpacity)
                            .frame(height: initialTextOpacity == 1 ? SCREEN_HEIGHT : 0)

                        VStack {
                            // Text counter and erase button
                            HStack {
                                Text("\(genPromptVm.promptInput.count)/\(charLimit) text")
                                    .foregroundColor(.ui.lighterLavBlue)
                                    .font(.ui.largeTitleMd)

                                Spacer()

                                Button {
                                    onErase()
                                    Haptics.shared.play(.soft)
                                    hideKeyboard()
                                } label: {
                                    Image("eraser")
                                        .resizable()
                                        .frame(width: 35, height: 35)
                                }

                            }.padding(10)

                            ZStack(alignment: .topLeading) {
                                if genPromptVm.promptInput.isEmpty {
                                    Text("\(placeholderText)")
                                        .foregroundColor(.ui.lighterLavBlue)
                                        .font(.ui.bodyLargest)
                                        .padding()
                                        .padding(.leading, -10)
                                        .padding(.top, -5)
                                        .lineSpacing(6)
                                        .opacity(genPromptVm.promptInput.isEmpty ? 1 : 0)
                                }

                                // Input text here
                                TextEditor(text: $genPromptVm.promptInput)
                                    .font(.ui.bodyLargest)
                                    .foregroundColor(Color.ui.cultured)
                                    .lineSpacing(6)
                                    .scrollContentBackground(.hidden)
                                    .onChange(of: genPromptVm.promptInput) { text in
                                        // Limit number of characters typed
                                        if text.count <= charLimit {
                                            lastText = text
                                        } else {
                                            self.genPromptVm.promptInput = lastText
                                        }

                                        // Detect when 'done' or a newline is generated
                                        if text.contains("\n") {
                                            self.genPromptVm.promptInput.removeAll(where: { $0.isNewline })
                                            hideKeyboard()
                                        }
                                    }
                                    .submitLabel(.done)
                            }
                        }
                        .opacity(initialTextOpacity == 1 ? 0 : 1)
                    }
                    .padding()
                )
        }
    }
}
