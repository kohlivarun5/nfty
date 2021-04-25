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
        .tabItem {
          Label("Collections", systemImage: "list.bullet.rectangle")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        NavigationView {
          FavoritesView()
            .navigationBarTitle("Favorites")
        }
        .tabItem {
          Label("Favorites", systemImage: "heart.text.square")
        }
        .navigationViewStyle(StackNavigationViewStyle())
      }
    }
  }
}
