//
//  UserWalletModel.swift
//  NFTY
//
//  Created by Varun Kohli on 7/31/21.
//

import Foundation
import Web3

class UserWallet: ObservableObject {
  @Published var walletAddress : EthereumAddress?
  init() {
    if let addr = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys
                                                            .walletAddress.rawValue) {
      self.walletAddress = try? EthereumAddress(hex:addr,eip55: false)
    } else {
      self.walletAddress = nil
    }
  }
  
  func saveWalletAddress(address:EthereumAddress) {
    NSUbiquitousKeyValueStore.default.set(address.hex(eip55:true), forKey:CloudDefaultStorageKeys.walletAddress.rawValue)
    self.walletAddress = address
  }
}
