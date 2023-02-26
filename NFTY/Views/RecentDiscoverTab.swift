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
    case posts = 0
    case avatars = 1
    case recent = 2
  }
  
  @State private var page : Page = .avatars
  
  var body: some View {
    
    VStack(spacing:0) {
      TabView(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          self.page = Page(rawValue: tag)!
        })) {
          ENSTextChangedFeedView(userWallet:userWallet,events:ENSTextChangedViewModel(key: "description", limit: 5))
            .tag(Page.posts.rawValue)
            .navigationBarTitle("Posts")
          ENSAvatarChangedFeedView(events:ENSTextChangedViewModel(key: "avatar", limit: 5))
            .tag(Page.avatars.rawValue)
            .navigationBarTitle("Avatars")
          FeedView(trades:CompositeCollection)
            .tag(Page.recent.rawValue)
            .navigationBarTitle("Trades")
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationBarTitleDisplayMode(.inline)
      
      
      Picker(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          self.page = Page(rawValue: tag)!
        }
      ), label: Text("")) {
        Text("Posts").tag(Page.posts.rawValue)
        Text("Avatars").tag(Page.avatars.rawValue)
        Text("Trades").tag(Page.recent.rawValue)
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
