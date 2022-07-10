//
//  main.swift
//  DownloadCollection
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation
import PromiseKit
import BigInt
import Web3
import Web3ContractABI


let collectionAddress = try! EthereumAddress(hex: "0xe21EBCD28d37A67757B9Bc7b290f4C4928A430b1", eip55: true)

let collection = MakeErc721Collection.ofAddress(address: collectionAddress)
let nft = collection.then { (collectionOpt:Collection?) -> Promise<NFT?> in
  guard let collection = collectionOpt else { return Promise.value(nil) }
  return collection.contract.getNFT(100)
}

let result = try(hang(nft))
