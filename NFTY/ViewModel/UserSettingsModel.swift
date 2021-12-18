//
//  UserSettingsModel.swift
//  NFTY
//
//  Created by Varun Kohli on 8/3/21.
//

import Foundation

class UserSettings: ObservableObject {
  
  enum DappBrowser : String,CaseIterable {
    case Native
    case Opera
    case Metamask
  }
  
  let userSettingsDappBrowserKey = "dappBrowser"
  @Published var dappBrowser : DappBrowser?
  
  let userSettingsQuoteTypeKey = "quoteType"
  
  enum QuoteType : String,CaseIterable {
    case Crypto
    case Both
    case Fiat
  }
  
  @Published var quoteType : QuoteType
  
  init() {
    dappBrowser =
      UserDefaults.standard.string(forKey: userSettingsDappBrowserKey)
      .flatMap { DappBrowser(rawValue: $0) }
    
    quoteType = (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.quoteType.rawValue) as? String)
      .flatMap { QuoteType(rawValue: $0) } ?? .Both
    
  }
  
  func updateDappBrowser(dappBrowser:DappBrowser) {
    UserDefaults.standard.set(dappBrowser.rawValue,forKey: userSettingsDappBrowserKey)
    self.dappBrowser = dappBrowser
  }
  
  func updateQuoteType(quoteType:QuoteType) {
    NSUbiquitousKeyValueStore.default.set(quoteType.rawValue,forKey:CloudDefaultStorageKeys.quoteType.rawValue)
    self.quoteType = quoteType
  }
}
