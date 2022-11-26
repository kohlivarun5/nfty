//
//  RecentDiscoverTab.swift
//  NFTY
//
//  Created by Varun Kohli on 8/6/22.
//

import SwiftUI

struct RecentDiscoverTab: View {
  
  @ObservedObject var userWallet : UserWallet
  
  private let avatarView : ENSAvatarChangedFeedView
  private let updatesView : ENSTextChangedFeedView
  private let feedView : FeedView
  
  init(userWallet:UserWallet) {
    self.userWallet = userWallet
    self.avatarView = ENSAvatarChangedFeedView(events:ENSTextChangedViewModel(key: "avatar", limit: 5))
    self.updatesView = ENSTextChangedFeedView(userWallet:userWallet,events:ENSTextChangedViewModel(key: "description", limit: 5))
    self.feedView = FeedView(trades:CompositeCollection)
  }
  
  enum Page : Int {
    case avatars
    case updates
    case recent
  }
  
  @State private var page : Page = .updates
  
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
