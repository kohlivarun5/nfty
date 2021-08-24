//
//  WalletProvider.swift
//  NFTY
//
//  Created by Varun Kohli on 8/4/21.
//

import Foundation
import Web3
import PromiseKit

protocol WalletProvider {
  var account : EthereumAddress { get }
  func sendTransaction(tx:EthereumTransaction) -> Promise<EthereumTransactionReceiptObject>
}
