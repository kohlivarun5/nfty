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

func fetchImage(_ nft:NFT) -> Promise<Media.IpfsImage?> {
  switch(nft.media) {
  case .ipfsImage(let image):
    return image.image.promise
  default:
    return Promise.value(nil)
  }
}


let collectionAddress = try! EthereumAddress(hex: "0xe21EBCD28d37A67757B9Bc7b290f4C4928A430b1", eip55: true)
let collection = MakeErc721Collection.ofName(name:"Saudis",address: collectionAddress)
let nft = collection.contract.getNFT(100)

let result = try(hang(fetchImage(nft)))
print(result)
