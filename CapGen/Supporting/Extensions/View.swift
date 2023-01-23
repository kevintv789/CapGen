//
//  View.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import Foundation
import SwiftUI

struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    
    // To use: .cornerRadius(14, corners: [.topLeft, .topRight])
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
    
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // Create extension for pop-up view
    // use the @ViewBuilder to create child views for a specific SwiftUI view in a readable way without having to use any return keywords.
    func modalView<Content: View>(horizontalPadding: CGFloat = 40.0, show: Binding<Bool>, @ViewBuilder content: @escaping () -> Content, onClickExit: (() -> ())?) -> some View {
        return self
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .overlay {
                if show.wrappedValue {
                    Color.ui.richBlack.opacity(0.35).ignoresSafeArea(.all)
                        .onTapGesture {
                            onClickExit?()
                        }
                    GeometryReader { geo in
                        let size = geo.size
                        
                        ZStack {
                            
                            content()
                            
                            Button {
                                onClickExit?()
                            } label: {
                                Image(systemName: "x.circle")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.ui.cadetBlueCrayola)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .opacity(onClickExit?() != nil ? 1 : 0)
                            .disabled(onClickExit?() == nil)
                            
                        }
                        .cornerRadius(16)
                        .frame(width: size.width - horizontalPadding, height: size.height / 2.5, alignment: .center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
            }
    }
}
