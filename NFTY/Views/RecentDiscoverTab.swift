//
//  RecentDiscoverTab.swift
//  NFTY
//
//  Created by Varun Kohli on 8/6/22.
//

import SwiftUI

struct RecentDiscoverTab: View {
  
  enum Page : Int {
    case avatars
    case updates
    case recent
  }
  
  @State private var page : Page = .updates
  
  let avatarView = ENSAvatarChangedFeedView(events:ENSTextChangedViewModel(key: "avatar", limit: 5))
  let updatesView = ENSTextChangedFeedView(events:ENSTextChangedViewModel(key: "description", limit: 5))
  let feedView = FeedView(trades:CompositeCollection)
  
  var body: some View {
    VStack(spacing:5) {
      switch(page) {
      case .avatars:
        avatarView
          .navigationBarTitle("Avatars",displayMode: .inline)
      case .updates:
        updatesView
          .navigationBarTitle("Updates",displayMode: .inline)
      case .recent:
        feedView
          .navigationBarTitle("Recent",displayMode: .inline)
      }
      Picker(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          self.page = Page(rawValue: tag)!
        }),
             label: Text("")) {
        Text("Avatars").tag(Page.avatars.rawValue)
        Text("Updates").tag(Page.updates.rawValue)
        Text("Recent").tag(Page.recent.rawValue)
      }
             .pickerStyle(SegmentedPickerStyle())
             .colorMultiply(.accentColor)
             .padding([.trailing,.leading])
             .padding(.bottom,7)
    }
  }
}

struct RecentDiscoverTab_Previews: PreviewProvider {
  static var previews: some View {
    RecentDiscoverTab()
  }
}
