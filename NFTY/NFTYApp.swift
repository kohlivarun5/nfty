//
//  NFTYApp.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import Firebase

@main
struct NFTYApp: App {
  init() { FirebaseApp.configure() }
  
  var body: some Scene {
    WindowGroup {
      TabView {
        NavigationView {
          CollectionsView(collections:COLLECTIONS)
            .navigationBarTitle("Collections")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .tabItem {
          Label("Collections", systemImage: "list.dash")
        }
        
        NavigationView {
          FavoritesView()
            .navigationBarTitle("Favorites")
        }
        .tabItem {
          Label("Favorites", systemImage: "heart.fill")
        }
      }
    }
  }
}
