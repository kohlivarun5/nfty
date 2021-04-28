//
//  NFT.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import Foundation
import SwiftUI
import Web3
import PromiseKit

enum TradeEventType {
  case offer
  case bought
}

struct TradeEvent {
  var type : TradeEventType
  var value : BigUInt
  var blockNumber : EthereumQuantity
}

struct NFT: Identifiable,Hashable, Codable {
  
  let address: String
  let tokenId: UInt
  let name: String
  let url: URL
  
  struct NftID : Hashable {
    let address: String
    let tokenId: UInt
    
    static func < (lhs: NftID, rhs: NftID) -> Bool {
      return lhs.address > rhs.address && lhs.tokenId < rhs.tokenId
    }
  }
  
  var id : NftID {
    return NftID(address:address,tokenId:tokenId)
  }
}

struct NFTWithPrice : Identifiable {
  let nft : NFT
  let indicativePriceWei : BigUInt?
  
  var id : NFT.NftID {
    return nft.id
  }
  
}

struct NFTWithLazyPrice : Identifiable {
  let nft : NFT
  let getPrice : () -> Promise<BigUInt?>
  
  var id : NFT.NftID {
    return nft.id
  }
  
  var indicativePriceWei : Promise<BigUInt?> {
    getPrice()
  }
}

enum TokenPriceType {
  case eager(BigUInt?)
  case lazy(Promise<BigUInt?>)
}

struct TokenDistance: Codable {
  let tokenId: Int
  let distance: Float
}

typealias SimilarTokensGetter = (UInt) -> [UInt]?
struct CollectionInfo {
  let address: String
  let url1: String
  let url2: String
  let url3: String
  let url4: String
  let name: String
  let totalSupply: Int
  let themeColor:Color
  let subThemeColor:Color
  let blur:CGFloat
  let samplePadding:CGFloat
  let similarTokens : SimilarTokensGetter
}

struct CollectionData : HasContractInterface {
  let recentTrades: NftRecentTradesObject
  let contract: ContractInterface
}

class Collection {
  let info : CollectionInfo
  let data : CollectionData
  init(info:CollectionInfo,data:CollectionData) {
    self.info = info;
    self.data = data;
  }
}

let SAMPLE_PUNKS : [String] = [
  "SamplePunk1",
  "SamplePunk2",
  "SamplePunk3",
  "SamplePunk4"
]

let SAMPLE_KITTIES : [String] = [
  "SampleKitty1",
  "SampleKitty2",
  "SampleKitty3",
  "SampleKitty4"
]

let CryptoPunksNfts : [NFT] = load("punks.json")
let CryptoPunks_nearestTokens : [[UInt]] = load("CryptoPunks_nearestTokens.json")

let CryptoKittiesNfts : [NFT] = load("kitties.json")

let cryptoPunksTrades = CryptoPunksTrades()
let cryptoKittiesTrades = CryptoKittiesTrades()

let CryptoPunksCollection = Collection(
  info:CollectionInfo(
    address:cryptoPunksTrades.contract.contractAddressHex,
    url1:SAMPLE_PUNKS[0],
    url2:SAMPLE_PUNKS[1],
    url3:SAMPLE_PUNKS[2],
    url4:SAMPLE_PUNKS[3],
    name:"CryptoPunks",
    totalSupply:10000,
    themeColor:Color.yellow,
    subThemeColor: /* FFB61E */ Color(red: 255/255, green: 182/255, blue: 30/255),
    blur:0,
    samplePadding:10,
    similarTokens : { tokenId in CryptoPunks_nearestTokens[safe:Int(tokenId)] }),
  data:CollectionData(recentTrades:cryptoPunksTrades,contract:cryptoPunksTrades.contract))

let CryptoKittiesCollection = Collection(
  info:CollectionInfo(
    address:cryptoKittiesTrades.contract.contractAddressHex,
    url1:SAMPLE_KITTIES[0],
    url2:SAMPLE_KITTIES[1],
    url3:SAMPLE_KITTIES[2],
    url4:SAMPLE_KITTIES[3],
    name:"CryptoKitties",
    totalSupply:1997622,
    themeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
    subThemeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
    blur:0,samplePadding:0,
    similarTokens: { tokenId in nil }),
  data:CollectionData(recentTrades:cryptoKittiesTrades,contract:cryptoKittiesTrades.contract))

let COLLECTIONS: [Collection]=[
  CryptoPunksCollection,
  CryptoKittiesCollection
]

struct CollectionsFactory {
  
  private let collections : [String : Collection] = [
    CryptoPunksCollection.info.address:CryptoPunksCollection,
    CryptoKittiesCollection.info.address:CryptoKittiesCollection
  ]
  
  func getByAddress(_ address:String) -> Collection? {
    return collections[address]
    //return nil
  }
  
}

let collectionsFactory = CollectionsFactory()

extension Array {
  subscript (safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }
}
