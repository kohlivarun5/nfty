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

enum Media {
  
  struct AsciiPunk {
    let unicode : String
  }
  
  struct AsciiPunkLazy {
    private var tokenId : BigUInt
    private let draw : (BigUInt) -> Promise<AsciiPunk?>
    
    init(tokenId:BigUInt,draw : @escaping (BigUInt) -> Promise<AsciiPunk?>) {
      self.tokenId = tokenId
      self.draw = draw
    }
    
    var ascii : Promise<AsciiPunk?> {
      self.draw(self.tokenId)
    }
  }
  
  case image(URL)
  case asciiPunk(AsciiPunkLazy)
}

struct NFT: Identifiable {
  
  let address: String
  let tokenId: UInt
  let name: String
  let media: Media
  
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
  private let getPrice : () -> Promise<BigUInt?>
  
  init(nft:NFT,getPrice : @escaping () -> Promise<BigUInt?>) {
    self.nft = nft
    self.getPrice = getPrice
  }
  
  var id : NFT.NftID {
    return nft.id
  }
  
  var indicativePriceWei : Promise<BigUInt?> {
    self.getPrice()
  }
}

enum TokenPriceType {
  case eager(BigUInt?)
  case lazy(Promise<BigUInt?>)
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
  let collectionColor:Color
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

let SampleToken = NFT(
  address: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb",
  tokenId: 340, name: "CryptoPunks",
  media: .image(URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk0385.png")!))

let CryptoPunks_nearestTokens : [[UInt]] = load("CryptoPunks_nearestTokens.json")

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
    collectionColor:Color.yellow,
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
    collectionColor:/* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
    blur:0,samplePadding:0,
    similarTokens: { tokenId in nil }),
  data:CollectionData(recentTrades:cryptoKittiesTrades,contract:cryptoKittiesTrades.contract))


public extension Color {
  static let lightText = Color(UIColor.lightText)
  static let darkText = Color(UIColor.darkText)
  
  static let label = Color(UIColor.label)
  static let secondaryLabel = Color(UIColor.secondaryLabel)
  static let tertiaryLabel = Color(UIColor.tertiaryLabel)
  static let quaternaryLabel = Color(UIColor.quaternaryLabel)
  
  static let systemBackground = Color(UIColor.systemBackground)
  static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
  static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
  
  // There are more..
}

let asciiPunksTrades = AsciiPunksTrades()
let SAMPLE_ASCII_PUNKS : [String] = [
  "AsciiPunk2",
  "AsciiPunk1000",
  "AsciiPunk1321",
  "AsciiPunk1307"
]
let AsciiPunksCollection = Collection(
  info:CollectionInfo(
    address:asciiPunksTrades.contract.contractAddressHex,
    url1:SAMPLE_ASCII_PUNKS[0],
    url2:SAMPLE_ASCII_PUNKS[1],
    url3:SAMPLE_ASCII_PUNKS[2],
    url4:SAMPLE_ASCII_PUNKS[3],
    name:"AsciiPunks",
    totalSupply:2048,
    themeColor:Color.label,
    subThemeColor:Color.black, // TODO
    collectionColor:Color.black,
    blur:0,
    samplePadding:10,
    similarTokens : { tokenId in nil }), // TODO
  data:CollectionData(recentTrades:asciiPunksTrades,contract:asciiPunksTrades.contract))

let COLLECTIONS: [Collection]=[
  CryptoPunksCollection,
  CryptoKittiesCollection,
  AsciiPunksCollection
]

struct CollectionsFactory {
  
  private let collections : [String : Collection] = [
    CryptoPunksCollection.info.address:CryptoPunksCollection,
    CryptoKittiesCollection.info.address:CryptoKittiesCollection,
    AsciiPunksCollection.info.address:AsciiPunksCollection,
  ]
  
  func getByAddress(_ address:String) -> Collection? {
    return collections[address]
  }
  
}

let collectionsFactory = CollectionsFactory()

extension Array {
  subscript (safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }
}

