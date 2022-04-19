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
  case ask
  case bid
  case bought
  case minted
  case transfer
}


enum PriceUnit : Codable,Comparable,Equatable {
  case wei(BigUInt)
  case near(BigUInt)
  
  public static func>(a: PriceUnit, b: PriceUnit) -> Bool {
    switch(a,b) {
    case (.wei(let x),.wei(let y)),
      (.near(let x),.near(let y)):
      return x > y
    case (.wei(let wei),.near(let near)):
      return (Double(wei) * 1e6 / Double(near)) > 0.005
    case (.near(let near),wei(let wei)):
      return (Double(wei) * 1e6 / Double(near)) <= 0.005
    }
  }
  
  public static func==(a: PriceUnit, b: PriceUnit) -> Bool {
    switch(a,b) {
    case (.wei(let x),.wei(let y)),
      (.near(let x),.near(let y)):
      return x == y
    case (.wei,.near),
         (.near,wei):
      return false
    }
  }
  
  public static func change(new:PriceUnit,prev:PriceUnit) -> Double? {
    switch(new,prev) {
    case (.wei(let x),.wei(let y)),
         (.near(let x),.near(let y)):
      return (Double(x) - Double(y)) / Double(y)
    case (.wei,.near):
      return nil
    case (.near,wei):
      return nil
    }
  }
}

enum BlockNumber : Codable,Comparable,Identifiable,Hashable {
  case ethereum(EthereumQuantity)
  case near(EthereumQuantity)
  
  public static func<(a: BlockNumber, b: BlockNumber) -> Bool {
    switch(a,b) {
    case (.ethereum(let x),.ethereum(let y)),
         (.near(let x),.near(let y)):
      return x.quantity < y.quantity
    case (.ethereum,.near):
      return false
    case (.near,ethereum):
      return true
    }
  }
  
  public static func>(a: BlockNumber, b: BlockNumber) -> Bool {
    switch(a,b) {
    case (.ethereum(let x),.ethereum(let y)),
         (.near(let x),.near(let y)):
      return x.quantity > y.quantity
    case (.ethereum,.near):
      return true
    case (.near,ethereum):
      return false
    }
  }
  
  var id : BigUInt {
    switch(self) {
    case .ethereum(let q),.near(let q):
      return q.quantity
    }
  }
  
}

struct TradeEvent {
  var type : TradeEventType
  var value : PriceUnit
  var blockNumber : BlockNumber
}

struct NFTNotSeenSince {
  var blockNumber : BlockNumber
}

enum TradeEventStatus {
  case trade(TradeEvent)
  case notSeenSince(NFTNotSeenSince)
}

protocol MediaImage {
  var url : ObservablePromise<URL> { get }
}

struct MediaImageLazy : MediaImage {
  let get : () -> ObservablePromise<URL>
  
  var url : ObservablePromise<URL> {
    self.get()
  }
}

struct MediaImageEager : MediaImage {
  let url : ObservablePromise<URL>
  init(_ url:URL) {
    self.url = ObservablePromise(resolved:url)
  }
}

enum Media {
  
  struct AsciiPunk : Codable {
    let unicode : String
  }
  
  struct AsciiPunkLazy {
    private var tokenId : BigUInt
    private let draw : (BigUInt) -> ObservablePromise<AsciiPunk?>
    
    init(tokenId:BigUInt,draw : @escaping (BigUInt) -> ObservablePromise<AsciiPunk?>) {
      self.tokenId = tokenId
      self.draw = draw
    }
    
    var ascii : ObservablePromise<AsciiPunk?> {
      self.draw(self.tokenId)
    }
  }
  
  struct Autoglyph : Codable {
    let utf8 : String
  }
  
  struct AutoglyphLazy {
    private var tokenId : BigUInt
    private let draw : (BigUInt) -> ObservablePromise<Autoglyph?>
    
    init(tokenId:BigUInt,draw : @escaping (BigUInt) -> ObservablePromise<Autoglyph?>) {
      self.tokenId = tokenId
      self.draw = draw
    }
    
    var autoglyph : ObservablePromise<Autoglyph?> {
      self.draw(self.tokenId)
    }
  }
  
  struct IpfsImage {
    let image : UIImage // let data : Data
    let image_hd : UIImage // let data : Data
    
    static func makeOpt(_ data:Data?) -> Media.IpfsImage? {
      return data
        .flatMap {
          UIImage(data:$0)
            .flatMap { image_hd in
              image_hd
                .jpegData(compressionQuality: 0.1)
                .flatMap { UIImage(data:$0) }
                .map { Media.IpfsImage(image:$0,image_hd:image_hd) }
            }
        }
    }
    
  }
  
  struct IpfsImageLazy {
    private var tokenId : BigUInt
    private let download : (BigUInt) -> ObservablePromise<IpfsImage?>
    
    init(tokenId:BigUInt,download : @escaping (BigUInt) -> ObservablePromise<IpfsImage?>) {
      self.tokenId = tokenId
      self.download = download
    }
    
    var image : ObservablePromise<IpfsImage?> {
      self.download(self.tokenId)
    }
  }
  
  case image(MediaImage)
  case asciiPunk(AsciiPunkLazy)
  case autoglyph(AutoglyphLazy)
  case ipfsImage(IpfsImageLazy)
}

struct NFT: Identifiable {
  
  let address: String
  let tokenId: BigUInt
  let name: String
  let media: Media
  
  struct NftID : Hashable {
    let address: String
    let tokenId: BigUInt
    
    static func < (lhs: NftID, rhs: NftID) -> Bool {
      return lhs.address > rhs.address && lhs.tokenId < rhs.tokenId
    }
  }
  
  var id : NftID {
    return NftID(address:address,tokenId:tokenId)
  }
}

struct NFTPriceInfo {
  
  let price : PriceUnit?
  
  enum BlockTimeStamp {
    case none
    case some(BlockNumber)
    case date(Date)
  }
  
  let blockNumber : BlockTimeStamp
  let type : TradeEventType
  
  init(price:PriceUnit?, blockNumber:BlockTimeStamp,type:TradeEventType) {
    self.price = price
    self.blockNumber = blockNumber
    self.type = type
  }
  
  init(wei:BigUInt?, blockNumber:BlockNumber?,type:TradeEventType) {
    self.price = wei.map { .wei($0) }
    self.type = type
    switch(blockNumber) {
    case .some(let x):
      self.blockNumber = BlockTimeStamp.some(x)
    case .none:
      self.blockNumber = BlockTimeStamp.none
    }
  }
  
  init(wei:BigUInt?, date:Date?,type:TradeEventType) {
    self.price = wei.map { .wei($0) }
    self.type = type
    switch(date) {
    case .some(let x):
      self.blockNumber = .date(x)
    case .none:
      self.blockNumber = .none
    }
  }
  
  init(near:BigUInt?, date:Date?,type:TradeEventType) {
    self.price = near.map { .near($0) }
    self.type = type
    switch(date) {
    case .some(let x):
      self.blockNumber = .date(x)
    case .none:
      self.blockNumber = .none
    }
  }
  
  init(near:BigUInt?, blockNumber:EthereumQuantity?,type:TradeEventType) {
    self.price = near.map { .near($0) }
    self.type = type
    switch(blockNumber) {
    case .some(let x):
      self.blockNumber = .some(.near(x))
    case .none:
      self.blockNumber = .none
    }
  }
  
}

struct NFTToken : Identifiable {
  let collection : Collection
  let nft : NFTWithLazyPrice
  
  var id : NFT.NftID { return self.nft.id }
}

enum NFTPriceStatus {
  case known(NFTPriceInfo)
  case notSeenSince(NFTNotSeenSince)
  case burnt
  case unavailable
}

enum TokenPriceType {
  case eager(NFTPriceInfo)
  case lazy(() -> ObservablePromise<NFTPriceStatus>)
}

struct Action {
  let account : UserAccount
  
  enum ActionType {
    case sold
  }
  let action : ActionType
}

struct NFTWithPrice : Identifiable {
  let nft : NFT
  let blockNumber : BlockNumber?
  let indicativePrice : TokenPriceType
  let action : Action?
  
  init(nft:NFT,blockNumber:BlockNumber?,indicativePrice:TokenPriceType,action:Action?=nil) {
    self.nft = nft
    self.blockNumber = blockNumber
    self.indicativePrice = indicativePrice
    self.action = action
  }
  
  var id : NFT.NftID {
    return nft.id
  }
}

struct TradeActionInfo {
  let tradeActions : TokenTradeInterface
  let bidAsk : Promise<BidAsk>
}

struct NFTWithLazyPrice : Identifiable {
  let nft : NFT
  private let getPrice : () -> ObservablePromise<NFTPriceStatus>
  
  init(nft:NFT,getPrice : @escaping () -> ObservablePromise<NFTPriceStatus>) {
    self.nft = nft
    self.getPrice = getPrice
  }
  
  var id : NFT.NftID {
    return nft.id
  }
  
  func indicativePrice() -> ObservablePromise<NFTPriceStatus> {
    self.getPrice()
  }
}

class SimilarTokensGetter {
  let label : String
  let nearestTokensFileName : String?
  let propertiesJsonFileName : String?
  
  var nearestTokens : [ [UInt] ]? = nil
  
  init(label:String,nearestTokensFileName:String) {
    self.label = label
    self.nearestTokensFileName = nearestTokensFileName
    self.propertiesJsonFileName = nil
  }
  
  init(label:String,nearestTokensFileName:String?,propertiesJsonFileName:String) {
    self.label = label
    self.nearestTokensFileName = nearestTokensFileName
    self.propertiesJsonFileName = propertiesJsonFileName
  }
  
  struct TokenAttributePercentile : Codable {
    let name : String
    let value : String
    let percentile : Double
  }
  
  func get(_ tokenId:BigUInt) -> [UInt]? {
    self.nearestTokens = self.nearestTokens ?? (nearestTokensFileName.map { load($0) } ?? [])
    return self.nearestTokens?[safe:Int(tokenId)]
  }
  
  func getProperties(_ tokenId:BigUInt) -> [TokenAttributePercentile]? {
    return self.properties?[safe:Int(tokenId)]
  }
  
  
  lazy var properties : [ [TokenAttributePercentile] ]? = {
    return propertiesJsonFileName.map { load($0) }
  }()
  
  lazy var availableProperties : [String:[String:Double]]? = {
    var availableProperties : [String:[String:Double]]? = nil
    self.properties?.forEach { itemProps in
      availableProperties = availableProperties ?? [:]
      itemProps.forEach { prop in
        if (prop.percentile >= 1) { return }
        
        var values = availableProperties![prop.name] ?? [:]
        values[prop.value] = prop.percentile
        availableProperties![prop.name] = values
      }
    }
    return availableProperties
  }()
  
  
}

protocol RarityRanking {
  var sortedTokenIds :  [UInt] { get }
  func getRank(_ tokenId:BigUInt) -> UInt?
}

class RarityRankingImpl : RarityRanking {
  let ranks : [UInt]
  let sortedTokenIds : [UInt]
  init(_ ranks:[UInt]) {
    self.ranks = ranks
    var indexed : [(Int,UInt)] = []
    for (index, element) in ranks.enumerated() {
      indexed.append((index,element))
    }
    indexed.sort { $0.1 < $1.1 }
    self.sortedTokenIds = indexed.map { UInt($0.0) }
  }
  
  func getRank(_ tokenId:BigUInt) -> UInt? { return ranks[safe:Int(tokenId)] }
}

struct CollectionInfo {
  let address: String
  let sample: String
  let name: String
  let webLink: URL?
  let themeColor:Color
  let themeLabelColor:Color
  let disableRecentTrades : Bool
  let similarTokens : SimilarTokensGetter?
  let rarityRanking : RarityRanking?
}

struct Collection {
  let info : CollectionInfo
  let contract: ContractInterface
}

struct NFTWithPriceAndInfo : Identifiable {
  let nftWithPrice : NFTWithPrice
  let info : CollectionInfo
  
  var id : NFT.NftID {
    return nftWithPrice.nft.id
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

let SAMPLE_ASCII_PUNKS : [String] = [
  "AsciiPunk2",
  "AsciiPunk1000",
  "AsciiPunk1321",
  "AsciiPunk1307"
]

let SAMPLE_AUTOGLYPHS : [String] = [
  "glyph2",
  "glyph7",
  "glyph178",
  "glyph374"
]

let SAMPLE_BAYC : [String] = [
  "SampleBAYC1",
  "SampleBAYC2",
  "SampleBAYC3",
  "SampleBAYC4"
]

let SAMPLE_FLS : [String] = [
  "SampleLady1",
  "SampleLady2",
  "SampleLady3",
  "SampleLady4"
]

let SAMPLE_CRHDL : [String] = [
  "SampleHodler1",
  "SampleHodler2",
  "SampleHodler3",
  "SampleHodler4"
]

let SAMPLE_CROWNS : [String] = [
  "SAMPLE_CROWN1",
  "SAMPLE_CROWN2",
  "SAMPLE_CROWN3",
  "SAMPLE_CROWN4"
]

let SAMPLE_CYPHER : [String] = [
  "SAMPLE_CYPHER1",
  "SAMPLE_CYPHER2",
  "SAMPLE_CYPHER3",
  "SAMPLE_CYPHER4"
]

let SAMPLE_CCB : [String] = [
  "SAMPLE_CCB1",
  "SAMPLE_CCB2",
  "SAMPLE_CCB3",
  "SAMPLE_CCB4"
]

let SAMPLE_TBH : [String] = [
  "SAMPLE_TBH1",
  "SAMPLE_TBH2",
  "SAMPLE_TBH3",
  "SAMPLE_TBH4"
]

let SAMPLE_COOL_CATS : [String] = [
  "COOL_CATS1",
  "COOL_CATS2",
  "COOL_CATS3",
  "COOL_CATS4"
]

let SAMPLE_DEAD_FELLAZ : [String] = [
  "DEAD_FELLAZ1",
  "DEAD_FELLAZ2",
  "DEAD_FELLAZ3",
  "DEAD_FELLAZ4"
]

let CryptoPunks_rarityRanks : [UInt] = load("CryptoPunks_rarityRanks.json")

let AsciiPunks_rarityRanks : [UInt] = load("AsciiPunks_rarityRanks.json")

let BAYC_rarityRanks : [UInt] = load("BoredApeYachtClub_rarityRanks.json")

let FLS_rarityRanks : [UInt] = load("FameLadySquad_rarityRanks.json")

let CRHDL_rarityRanks : [UInt] = load("CryptoHodlers_rarityRanks.json")

let CCD_rarityRanks : [UInt] = load("CryptoCannabisClub_rarityRanks.json")

let CypherCity_rarityRanks : [UInt] = load("CypherCity_rarityRanks.json")

let BirdHouse_rarityRanks : [UInt] = load("BirdHouse_rarityRanks.json")

let CoolCats_rarityRanks : [UInt] = load("CoolCats_rarityRanks.json")

let DeadFellaz_rarityRanks : [UInt] = load("DeadFellaz_rarityRanks.json")
