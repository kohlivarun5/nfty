//
//  NFTYApp.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import Web3

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
    case user(EthereumAddress,friendName:String?)
  }
  struct SheetState : Identifiable {
    let state : SheetStateEnum
    
    var id : String {
      switch state {
      case .nft(let address,let tokenId):
        return "nft(\(address),\(tokenId))"
      case .user(let address,let friendName):
        return "user(\(address.hex(eip55:true)),\(friendName ?? ""))"
      }
    }
  }
  
  @State private var sheetState : SheetState? = nil
  
  @StateObject var userWallet = UserWallet()
  
  var body: some Scene {
    WindowGroup {
      TabView {
        
        NavigationView {
          FeedView(trades:CompositeCollection)
            .navigationBarTitle("Recent")
        }
        .tabItem {
          Label("Recent",systemImage:"sparkles.rectangle.stack.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        NavigationView {
          CollectionsView(collections:COLLECTIONS)
            .navigationBarTitle("Gallery")
        }
        .tabItem {
          Label("Gallery",systemImage:"square.grid.3x1.fill.below.line.grid.1x2")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        if (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) != nil) {
          
          NavigationView {
            FriendsView()
              .navigationBarTitle("Friends")
          }
          .tabItem {
            Label("Friends",systemImage:"person.2.square.stack")
          }
          .navigationViewStyle(StackNavigationViewStyle())
        }
        
        NavigationView {
          FavoritesView()
            .navigationBarTitle("Favorites")
        }
        .tabItem {
          Label("Favorites",systemImage:"heart.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        NavigationView {
          WalletView()
        }
        .tabItem {
          Label("Wallet",systemImage:"lock.rectangle.stack.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
      }
      // .preferredColorScheme(.dark)
      .accentColor(.orange)
      .onAppear {
        
        // Load collections on wakeup : https://github.com/EtherTix/nfty/issues/162
        DispatchQueue.global(qos:.utility).async {
          CompositeCollection.collections.forEach { collection in
            print(
              collection.info.name,
              collection.info.similarTokens?.get(1)?.count,
              collection.info.similarTokens?.getProperties(1)?.count,
              collection.info.similarTokens?.availableProperties?.count
            )
          }
          
        }
      }
      .onOpenURL { url in
        print("URL=\(url)") // comes as https://nftygo.com/nft?address=0x5283Fc3a1Aac4DaC6B9581d3Ab65f4EE2f3dE7DC&tokenId=1974
        print("URL.last=\(String(describing: url.pathComponents.last))")
        print("URL.params=\(url.params())")
        
        switch url.pathComponents.last {
        case .some("nft"):
          let params = url.params()
          switch (params["address"] as? String,(params["tokenId"] as? String).flatMap { UInt($0) }) {
          case (.some(let address),.some(let tokenId)):
            self.sheetState = SheetState(state: .nft(address,tokenId))
          default:
            break
          }
        case .some("user"):
          let params = url.params()
          switch (params["address"] as? String).flatMap({ try? EthereumAddress(hex:$0,eip55:false) }) {
          case .some(let address):
            self.sheetState = SheetState(state: .user(address,friendName:params["name"] as? String))
          case .none:
            break
          }
        default:
          break
        }
      }.sheet(item: $sheetState, onDismiss: { self.sheetState = nil }) { (item:SheetState) in
        switch item.state {
        case .nft(let address,let tokenId):
          NftUrlView(address: address, tokenId: tokenId)
            // .preferredColorScheme(.dark)
            .accentColor(Color.orange)
        case .user(let address,let friendName):
          UserUrlView(address: address,friendName:friendName)
            // .preferredColorScheme(.dark)
            .accentColor(Color.orange)
        }
      }
      .animation(.none)
      // .preferredColorScheme(.dark)
      .accentColor(Color.orange)
      
      .environmentObject(userWallet)
    }
  }
}
