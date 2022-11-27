  //
  //  RecentDiscoverTab.swift
  //  NFTY
  //
  //  Created by Varun Kohli on 8/6/22.
  //

import SwiftUI

struct RecentDiscoverTab: View {
  
  @ObservedObject var userWallet : UserWallet
  
  enum Page : Int {
    case avatars
    case updates
    case recent
  }
  
  @State private var page : Page = .updates
  
  var body: some View {
    
    VStack(spacing:0) {
      TabView(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          self.page = Page(rawValue: tag)!
        })) {
          ENSAvatarChangedFeedView(events:ENSTextChangedViewModel(key: "avatar", limit: 5))
            .tag(Page.avatars.rawValue)
            .navigationBarTitle("Avatars")
          ENSTextChangedFeedView(userWallet:userWallet,events:ENSTextChangedViewModel(key: "description", limit: 5))
            .tag(Page.updates.rawValue)
            .navigationBarTitle("Updates")
          FeedView(trades:CompositeCollection)
            .tag(Page.recent.rawValue)
            .navigationBarTitle("Recent")
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationBarTitleDisplayMode(.inline)
      
      
      Picker(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          self.page = Page(rawValue: tag)!
        }
      ), label: Text("")) {
        Text("Avatars")
          .tag(Page.avatars.rawValue)
        Text("Updates").tag(Page.updates.rawValue)
        Text("Recent").tag(Page.recent.rawValue)
      }
      .pickerStyle(SegmentedPickerStyle())
      .colorMultiply(.accentColor)
      .padding([.trailing,.leading])
      .padding(.bottom,5)
      .padding(.top,10)
      .background(.ultraThinMaterial)
    }
    
  }
}
