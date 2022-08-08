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
    case recent
  }
  
  @State private var page : Page = .avatars
  
  let avatarEvents =  ENSTextChangedViewModel(key: "avatar", limit: 5)
  
  var body: some View {
    VStack(spacing:5) {
      switch(page) {
      case .avatars:
        ENSAvatarChangedFeedView(events:avatarEvents)
          .navigationBarTitle("Discover",displayMode: .inline)
      case .recent:
        FeedView(trades:CompositeCollection)
          .navigationBarTitle("Recent",displayMode: .inline)
      }
      Picker(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          self.page = Page(rawValue: tag)!
        }),
             label: Text("")) {
        Text("Discover").tag(Page.avatars.rawValue)
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
