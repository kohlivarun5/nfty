//
//  SavedFavsUsersView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/7/22.
//

import SwiftUI
import Web3

struct SavedFavsUsersView: View {
  
  enum Page : Int {
    case items
    case users
  }
  
  @State private var page : Page = .items
  
  let friends : [String : String]
  let addresses : [EthereumAddress]
  
  var body: some View {
    VStack(spacing:5) {
      switch(page) {
      case .items:
        FavoritesView()
          .navigationBarTitle("Items",displayMode: .inline)
      case .users:
        FriendsListView(friends:friends,addresses:addresses)
          .navigationBarTitle("Users",displayMode: .inline)
      }
      Picker(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          withAnimation { // needed explicit for transitions
            self.page = Page(rawValue: tag)!
          }
        }),
             label: Text("")) {
        Text("Items").tag(Page.items.rawValue)
        Text("Users").tag(Page.users.rawValue)
      }
             .pickerStyle(SegmentedPickerStyle())
             .colorMultiply(.accentColor)
             .padding([.trailing,.leading])
             .padding(.bottom,7)
    }
  }
}
