//
//  TokenProtocols.swift
//  NFTY
//
//  Created by Varun Kohli on 4/21/21.
//

import Foundation

import Web3

// Optional
import Web3PromiseKit
import Web3ContractABI

let logger = Logger()

protocol NftRecentTrades {
  func getRecentTrades() -> Promise<[NFT]>
}


struct CryptoTrades : NftRecentTrades {
  private var web3 = Web3(rpcURL: "https://mainnet.infura.io/<your_infura_id>")
  private var contractAddress = try EthereumAddress(hex: "0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0", eip55: true)
  private var contractJsonABI = "<your contract ABI as a JSON string>".data(using: .utf8)!
  private var contract = try web3.eth.Contract(json: contractJsonABI, abiKey: nil, address: contractAddress)
  func getRecentTrades() {
    
    // Get balance of some address
    firstly {
      try contract["balanceOf"]!(EthereumAddress(hex: "0x3edB3b95DDe29580FFC04b46A68a31dD46106a4a", eip55: true)).call()
    }.done { outputs in
      logger.info("Balance=\(outputs["_balance"] as? BigUInt))")
      // print(outputs["_balance"] as? BigUInt)
    }.catch { error in
      print(error)
    }
  }
}
