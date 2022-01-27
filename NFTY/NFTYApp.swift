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

class AppDelegateState: ObservableObject {
  static let shared = AppDelegateState()
  
  enum SheetStateEnum {
    case nft(String,UInt)
    case nftTrade(String,UInt)
    case user(EthereumAddress,friendName:String?)
  }
  struct SheetState : Identifiable {
    let state : SheetStateEnum
    
    var id : String {
      switch state {
      case .nft(let address,let tokenId):
        return "nft(\(address),\(tokenId))"
      case .nftTrade(let address,let tokenId):
        return "nftTrade(\(address),\(tokenId))"
      case .user(let address,let friendName):
        return "user(\(address.hex(eip55:true)),\(friendName ?? ""))"
      }
    }
  }
  
  @Published var sheetState : SheetState? = nil
}

class AppDelegate: NSObject,UIApplicationDelegate,UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // UIApplication.backgroundFetchIntervalMinimum = 0s
    UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    
    // Period: 3600s = 1 hour
    UIApplication.shared.setMinimumBackgroundFetchInterval(600)
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { success, error in
      if success {
        print("Notifications approved")
      } else if let error = error {
        print(error.localizedDescription)
      }
    }
    
    UNUserNotificationCenter.current().delegate = self
    
    return true
  }
  
  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("Background fetch called")
    
    performBackgroundFetch()
      .done {
        completionHandler($0 ? .newData : .noData)
      }
      .catch {
        // called when any promises throw an error
        print($0)
        completionHandler(.failed)
      }.finally {
        CompositeCollection.loadLatest {
          print("Loaded latest trades")
          CompositeCollection.recentTrades.forEach {
            switch($0.nft.nftWithPrice.nft.media) {
            case .ipfsImage(let image):
              image.image.load()
            case .image(let image):
              image.url.load()
            case .asciiPunk,.autoglyph:
              return
            }
          }
        }
      }
  }
  
  // This function will be called right after user tap on the notification
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    print("app opened from PushNotification tap")
    print(response)
    print(response.notification.request.content.userInfo)
    
    let userInfo = response.notification.request.content.userInfo
    
    if let sheetState = userInfo["sheetState"] as? String {
      switch(sheetState) {
      case "nft":
        AppDelegateState.shared.sheetState = AppDelegateState.SheetState(state:.nft(userInfo["address"] as! String,userInfo["tokenId"] as! UInt))
      case "nftTrade":
        AppDelegateState.shared.sheetState = AppDelegateState.SheetState(state:.nftTrade(userInfo["address"] as! String,userInfo["tokenId"] as! UInt))
      default:
        print("Do not know how to display sheetState=\(sheetState)")
      }
    }
    
    completionHandler()
  }
  
}


@main
struct NFTYApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  
  @ObservedObject var appDelegateState = AppDelegateState.shared
  
  @StateObject var userWallet = UserWallet()
  
  var body: some Scene {
    WindowGroup {
      TabView {
        
        NavigationView {
          WalletView()
        }
        .tabItem {
          Label("Wallet",systemImage:"lock.rectangle.stack.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        NavigationView {
          FavoritesView()
            .navigationBarTitle("Favorites")
        }
        .tabItem {
          Label("Favorites",systemImage:"heart.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        NavigationView {
          FeedView(trades:CompositeCollection)
            .navigationBarTitle("Recent")
        }
        .tabItem {
          Label("Recent",systemImage:"sparkles.rectangle.stack.fill")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        NavigationView {
          CollectionsView(collections:CompositeCollection.loaders)
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
        
        
      }
      // .preferredColorScheme(.dark)
      .accentColor(.orange)
      .onAppear {
        
        DispatchQueue.global(qos:.utility).asyncAfter(deadline: .now() + 1) {
          CompositeCollection.getRecentTrades(currentIndex: 0) {
            print("Loaded feed")
          }
        }
        // Load collections on wakeup : https://github.com/EtherTix/nfty/issues/162
        /*
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
         */
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
            self.appDelegateState.sheetState = AppDelegateState.SheetState(state: .nft(address,tokenId))
          default:
            break
          }
        case .some("user"):
          let params = url.params()
          switch (params["address"] as? String).flatMap({ try? EthereumAddress(hex:$0,eip55:false) }) {
          case .some(let address):
            self.appDelegateState.sheetState = AppDelegateState.SheetState(state: .user(address,friendName:params["name"] as? String))
          case .none:
            break
          }
        default:
          break
        }
      }.sheet(item: $appDelegateState.sheetState, onDismiss: { self.appDelegateState.sheetState = nil }) { (item:AppDelegateState.SheetState) in
        switch item.state {
        case .nft(let address,let tokenId):
          NavigationView {
            ObservedPromiseView(
              data: ObservablePromise(
                promise: collectionsFactory.getByAddress(address)),
              progress: {
                ProgressView()
              },
              view: { collection in
                NftUrlView(collection: collection, tokenId: tokenId)
              }
            )
          }
          .preferredColorScheme(.dark)
          .accentColor(Color.orange)
        case .nftTrade(let address,let tokenId):
          ObservedPromiseView(
            data: ObservablePromise(
              promise: collectionsFactory.getByAddress(address)),
            progress: {
              ProgressView()
            },
            view: { collection in
              NftTradeUrlView(collection: collection, tokenId: tokenId, userWallet: userWallet)
                .accentColor(.orange)
                .ignoresSafeArea(edges: .bottom)
            }
          )
        case .user(let address,let friendName):
          UserUrlView(address: address,friendName:friendName)
            .preferredColorScheme(.dark)
            .accentColor(Color.orange)
        }
      }
      .animation(.none)
      .preferredColorScheme(.dark)
      .accentColor(Color.orange)
      
      .environmentObject(userWallet)
    }
  }
  
  
  
}

