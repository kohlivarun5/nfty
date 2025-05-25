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
    case user(EthereumAddress,friendName:String?,page:PrivateCollectionView.TokensPage?)
  }
  struct SheetState : Identifiable {
    let state : SheetStateEnum
    
    var id : String {
      switch state {
      case .nft(let address,let tokenId):
        return "nft(\(address),\(tokenId))"
      case .nftTrade(let address,let tokenId):
        return "nftTrade(\(address),\(tokenId))"
      case .user(let address,let friendName,let page):
        return "user(\(address.hex(eip55:true)),\(friendName ?? ""),\(page?.rawValue ?? -1))"
      }
    }
  }
  
  @Published var sheetState : SheetState? = nil
}

/*
 import Firebase
 import FirebaseAppCheck
 
 class NFTYAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
 func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
 return AppAttestProvider(app: app)
 }
 }
 */

class AppDelegate: NSObject,UIApplicationDelegate,UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // let providerFactory = NFTYAppCheckProviderFactory()
    // AppCheck.setAppCheckProviderFactory(providerFactory)
    // FirebaseApp.configure()
    
    UIApplication.shared.setMinimumBackgroundFetchInterval(60 * 5)
    
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
        (userInfo["tokenId"] as? String).flatMap { UInt($0) }.map {
          AppDelegateState.shared.sheetState = AppDelegateState.SheetState(state:.nft(userInfo["address"] as! String,$0))
        }
      case "nftTrade":
        (userInfo["tokenId"] as? String).flatMap { UInt($0) }.map {
          AppDelegateState.shared.sheetState = AppDelegateState.SheetState(state:.nftTrade(userInfo["address"] as! String,$0))
        }
      case "user":
        (userInfo["ethereumAddress"] as? String).flatMap { try? EthereumAddress(hex: $0, eip55: false) }.map {
          AppDelegateState.shared.sheetState = AppDelegateState.SheetState(
            state:.user(
              $0,
              friendName: userInfo["friendName"] as? String,
              page:(userInfo["page"] as? Int).flatMap { PrivateCollectionView.TokensPage(rawValue: $0) })
          )
        }
      default:
        print("Do not know how to display sheetState=\(sheetState)")
      }
    }
    
    completionHandler()
  }
  
}


@main
struct NFTYApp: App {
  init() {
    AppKitConfig.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onOpenURL { url in
          AppKit.instance.handleDeeplink(url)
        }
    }
  }
}

