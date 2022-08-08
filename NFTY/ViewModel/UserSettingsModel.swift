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
    case Coinbase
  }
  
  let userSettingsDappBrowserKey = "dappBrowser"
  @Published var dappBrowser : DappBrowser
  
  let userSettingsQuoteTypeKey = "quoteType"
  
  enum QuoteType : String,CaseIterable {
    case Crypto
    case Both
    case Fiat
  }
  
  @Published var quoteType : QuoteType
  
  enum OfferNotificationMinimumType : String,CaseIterable {
    case None = "No Limit"
    case OTM_20_pct = "20% below floor"
    case OTM_10_pct = "10% below floor"
    case OTM_5_pct = "5% below floor"
    case ATM = "At Floor"
    case ITM_5_pct = "5% above floor"
    case ITM_10_pct = "10% above floor"
    case ITM_20_pct = "20% above floor"
  }
  
  @Published var offerNotificationMinimum : OfferNotificationMinimumType
  
  init() {
    dappBrowser =
      UserDefaults.standard.string(forKey: userSettingsDappBrowserKey)
      .flatMap { DappBrowser(rawValue: $0) } ?? DappBrowser.Native
    
    quoteType = (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.quoteType.rawValue) as? String)
      .flatMap { QuoteType(rawValue: $0) } ?? .Both
    
    offerNotificationMinimum = (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.offerNotificationMinimum.rawValue) as? String)
      .flatMap { OfferNotificationMinimumType(rawValue: $0) } ?? .OTM_20_pct
    
  }
  
  func updateDappBrowser(dappBrowser:DappBrowser) {
    UserDefaults.standard.set(dappBrowser.rawValue,forKey: userSettingsDappBrowserKey)
    self.dappBrowser = dappBrowser
  }
  
  func updateQuoteType(quoteType:QuoteType) {
    NSUbiquitousKeyValueStore.default.set(quoteType.rawValue,forKey:CloudDefaultStorageKeys.quoteType.rawValue)
    self.quoteType = quoteType
  }
  
  func updateOfferNotificationMinimum(offerNotificationMinimum:OfferNotificationMinimumType) {
    NSUbiquitousKeyValueStore.default.set(offerNotificationMinimum.rawValue,forKey:CloudDefaultStorageKeys.offerNotificationMinimum.rawValue)
    print(offerNotificationMinimum)
    self.offerNotificationMinimum = offerNotificationMinimum
  }
}
