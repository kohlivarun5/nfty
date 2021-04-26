//
//  NFT.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import Foundation
import SwiftUI
import Web3

enum TradeEventType {
  case offer
  case bought
}

struct TradeEvent {
  var type : TradeEventType
  var value : BigUInt
  var blockNumber : EthereumQuantity
}

struct NFT: Hashable, Codable {
  var address: String
  var tokenId: UInt
  var name: String
  var url: URL
  var indicativePriceWei: BigUInt?
}

struct TokenDistance: Codable {
  var tokenId: Int
  var distance: Float
}

struct CollectionInfo {
  var address: String
  var url1: String
  var url2: String
  var url3: String
  var url4: String
  var name: String
  var totalSupply: Int
  var themeColor:Color
  var blur:CGFloat
  var samplePadding:CGFloat
  var similarTokens : (UInt) -> [TokenDistance]?
}

struct CollectionData : HasContractInterface {
  var recentTrades: NftRecentTradesObject
  var contract: ContractInterface
}

class Collection {
  var info : CollectionInfo
  var data : CollectionData
  init(info:CollectionInfo,data:CollectionData) {
    self.info = info;
    self.data = data;
  }
}

var SAMPLE_PUNKS : [String] = [
  "SamplePunk1",
  "SamplePunk2",
  "SamplePunk3",
  "SamplePunk4"
]

var SAMPLE_KITTIES : [String] = [
  "SampleKitty1",
  "SampleKitty2",
  "SampleKitty3",
  "SampleKitty4"
]

var CryptoPunksNfts : [NFT] = load("punks.json")

var CryptoPunksDistances : [[TokenDistance]] = load("CryptoPunksDistances.json")

var CryptoKittiesNfts : [NFT] = load("kitties.json")

var cryptoPunksTrades = CryptoPunksTrades()
var cryptoKittiesTrades = CryptoKittiesTrades()

var CryptoPunksCollection = Collection(
  info:CollectionInfo(
    address:cryptoPunksTrades.contract.contractAddressHex,
    url1:SAMPLE_PUNKS[0],
    url2:SAMPLE_PUNKS[1],
    url3:SAMPLE_PUNKS[2],
    url4:SAMPLE_PUNKS[3],
    name:"CryptoPunks",
    totalSupply:10000,
    themeColor:Color.yellow,
    blur:0,
    samplePadding:10,
    similarTokens : { tokenId in CryptoPunksDistances[safe:Int(0)] }),
  data:CollectionData(recentTrades:cryptoPunksTrades,contract:cryptoPunksTrades.contract))
var CryptoKittiesCollection = Collection(
  info:CollectionInfo(
    address:cryptoKittiesTrades.contract.contractAddressHex,
    url1:SAMPLE_KITTIES[0],
    url2:SAMPLE_KITTIES[1],
    url3:SAMPLE_KITTIES[2],
    url4:SAMPLE_KITTIES[3],
    name:"CryptoKitties",
    totalSupply:1997622,
    themeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
    blur:0,samplePadding:0,
    similarTokens: { tokenId in nil }),
  data:CollectionData(recentTrades:cryptoKittiesTrades,contract:cryptoKittiesTrades.contract))

var COLLECTIONS: [Collection]=[
  CryptoPunksCollection,
  CryptoKittiesCollection
]

struct CollectionsFactory {
  
  private var collections : [String : Collection] = [
    CryptoPunksCollection.info.address:CryptoPunksCollection,
    CryptoKittiesCollection.info.address:CryptoKittiesCollection
  ]
  
  func getByAddress(_ address:String) -> Collection? {
    return collections[address]
    //return nil
  }
  
}

var collectionsFactory = CollectionsFactory()

extension Array {
  subscript (safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }
}
