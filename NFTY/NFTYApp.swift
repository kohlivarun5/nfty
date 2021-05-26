//
//  NFTYApp.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

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
  enum SheetStateEnum {
    case nft(String,UInt)
  }
  struct SheetState : Identifiable {
    let state : SheetStateEnum
    
    var id : String {
      switch state {
      case .nft(let address,let tokenId):
        return "nft(\(address),\(tokenId))"
      }
    }
  }
  
  @State private var sheetState : SheetState? = nil
  @State private var showSheet : Bool = false
  
  var body: some Scene {
    WindowGroup {
      TabView {
        
        NavigationView {
          CollectionsView(collections:COLLECTIONS)
            .navigationBarTitle("Gallery")
        }
        .tabItem {
          Label("Gallery",systemImage:"square.grid.3x1.fill.below.line.grid.1x2")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.secondary)
        
        
        NavigationView {
          FeedView(trades:CompositeCollection)
            .navigationBarTitle("Recent")
        }
        .tabItem {
          Label("Recent",systemImage:"sparkles.rectangle.stack.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.secondary)
        
        
        NavigationView {
          FriendsView()
            .navigationBarTitle("Friends")
        }
        .tabItem {
          Label("Friends",systemImage:"person.2.square.stack")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.secondary)
        
        NavigationView {
          FavoritesView()
            .navigationBarTitle("Favorites")
        }
        .tabItem {
          Label("Favorites",systemImage:"heart.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.secondary)
        
        NavigationView {
          WalletView()
            .navigationBarTitle("Wallet",displayMode: .inline)
        }
        .tabItem {
          Label("Wallet",systemImage:"lock.rectangle.stack.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.secondary)
        
        
      }.onOpenURL { url in
        print("URL=\(url)") // comes as https://nftygo.com/nft?address=0x5283Fc3a1Aac4DaC6B9581d3Ab65f4EE2f3dE7DC&tokenId=1974
        print("URL.last=\(url.pathComponents.last)")
        print("URL.params=\(url.params())")
        
        switch url.pathComponents.last {
        case .some("nft"):
          let params = url.params()
          switch (params["address"] as? String,(params["tokenId"] as? String).flatMap { UInt($0) }) {
          case (.some(let address),.some(let tokenId)):
            self.sheetState = SheetState(state: .nft(address,tokenId))
            print(self.sheetState)
            self.showSheet = true
          default:
            break
          }
        default:
          break
        }
      }.sheet(item: $sheetState, onDismiss: { self.showSheet = nil }) { (item:SheetState) in
        switch item.state {
        case .nft(let address,let tokenId):
          NftUrlView(address: address, tokenId: tokenId)
        }
      }
      
    }
  }
}
