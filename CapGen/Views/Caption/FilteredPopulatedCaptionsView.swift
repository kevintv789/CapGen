//
//  FilteredPopulatedCaptionsView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/13/23.
//

import SwiftUI

struct FilteredPopulatedCaptionsView: View {
    @Binding var searchText: String
    
    var body: some View {
        ZStack {
            
            if searchText.isEmpty {
                NoSearchResultsView(title: "Looking for something specific?", subtitle: "Type your search term above and we'll scour our content for any captions that match your keyword.")
            }
           
        }
        
    }
}

struct FilteredPopulatedCaptionsView_Previews: PreviewProvider {
    static var previews: some View {
        FilteredPopulatedCaptionsView(searchText: .constant(""))
    }
}

struct NoSearchResultsView: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .foregroundColor(.ui.cadetBlueCrayola)
                .font(.ui.headline)
            
            Text(subtitle)
                .foregroundColor(.ui.cadetBlueCrayola)
                .font(.ui.headlineRegular)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
        .frame(width: SCREEN_WIDTH * 0.8)
        .padding(.top, 100)
    }
}
