//
//  SearchBar.swift
//  CapGen
//
//  Created by Kevin Vu on 2/13/23.
//

import SwiftUI

struct SearchBar: View {
    var searchBarWidth: CGFloat = 0
    @Binding var isSearching: Bool
    @Binding var searchText: String
    // focus state of the search bar
    @FocusState private var isFocused: Bool
    var onCancelSearch: () -> Void

    var body: some View {
        // search bar with an image icon 
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.ui.cultured)
                .frame(width: searchBarWidth, height: 50)
                .overlay(
                    HStack {
                        Image("search-gray")
                            .resizable()
                            .frame(width: 25, height: 25)

                        TextField("", text: $searchText)
                            .placeholder(when: searchText.isEmpty) {
                                Text("Search...")
                                    .foregroundColor(.ui.cadetBlueCrayola)
                            }
                            .padding(.leading, 8)
                            .font(.ui.headline)
                            .focused($isFocused)
                            .foregroundColor(.ui.richBlack)
                           
                        if !searchText.isEmpty {
                            Button {
                                Haptics.shared.play(.soft)
                                searchText.removeAll()
                            } label: {
                                Image(systemName: "x.circle.fill")
                                    .font(.ui.headline)
                                    .foregroundColor(.ui.cadetBlueCrayola)
                            }
                        }
                      
                    }
                    .padding()
                )

            Button(action: {
                Haptics.shared.play(.soft)
                onCancelSearch()
                hideKeyboard()
            }, label: {
                Text("Cancel")
                    .foregroundColor(.ui.richBlack)
                    .padding(.trailing, 8)
                    .font(.ui.headline)
            })
            .padding(.leading, 15)
        }
        .onChange(of: self.isSearching, perform: { isSearching in
            if (isSearching) {
                self.isFocused.toggle()
            }
        })
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(isSearching: .constant(false), searchText: .constant(""), onCancelSearch: {})
    }
}
