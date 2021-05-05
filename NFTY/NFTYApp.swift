//
//  NFTYApp.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import Firebase

extension UINavigationController: UIGestureRecognizerDelegate {
  override open func viewDidLoad() {
    super.viewDidLoad()
    interactivePopGestureRecognizer?.delegate = self
  }
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return viewControllers.count > 1
  }
}

@main
struct NFTYApp: App {
  init() { FirebaseApp.configure() }
  
  var body: some Scene {
    WindowGroup {
      TabView {
        
        NavigationView {
          FeedView(trades:CompositeCollection)
            .navigationBarTitle("Recent")
        }
        .tabItem {
          Image(systemName:"sparkles.rectangle.stack.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.secondary)
        
        NavigationView {
          CollectionsView(collections:COLLECTIONS)
            .navigationBarTitle("Gallery")
        }
        .tabItem {
          Image(systemName:"square.grid.3x1.fill.below.line.grid.1x2")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.secondary)
        
        NavigationView {
          FavoritesView()
            .navigationBarTitle("Favorites")
        }
        .tabItem {
          Image(systemName:"heart.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.secondary)
      }
    }
  }
}
