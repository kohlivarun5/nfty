//
//  WidgetStorage.swift
//  NFTY
//
//  Created by Varun Kohli on 1/11/22.
//

import Foundation
import Web3

class WidgetStorage {
  var walletAddress : EthereumAddress?
  var nearAccount : String?
  
  init() {
    if let addr = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys
                                                            .walletAddress.rawValue) {
      self.walletAddress = try? EthereumAddress(hex:addr,eip55: false)
    } else {
      self.walletAddress = nil
    }
    
    if let nearAccount = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys
                                                            .nearAccount.rawValue) {
      self.nearAccount = nearAccount
    } else {
      self.nearAccount = nil
    }
  }
  
  func userAccount() -> UserAccount {
    return UserAccount(ethAddress: self.walletAddress, nearAccount: self.nearAccount)
  }
}
