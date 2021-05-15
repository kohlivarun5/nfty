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

struct NFTNotSeenSince {
  var blockNumber : BigUInt
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
  
  struct AsciiPunk {
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
  
  struct Autoglyph {
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
  
  case image(MediaImage)
  case asciiPunk(AsciiPunkLazy)
  case autoglyph(AutoglyphLazy)
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

struct NFTPriceInfo {
  let price : BigUInt?
  let blockNumber : BigUInt?
}

struct NFTWithPrice : Identifiable {
  let nft : NFT
  let indicativePriceWei : NFTPriceInfo
  
  var id : NFT.NftID {
    return nft.id
  }
}

enum NFTPriceStatus {
  case known(NFTPriceInfo)
  case notSeenSince(NFTNotSeenSince)
  case burnt
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
  
  var indicativePriceWei : ObservablePromise<NFTPriceStatus> {
    self.getPrice()
  }
}

enum TokenPriceType {
  case eager(NFTPriceInfo)
  case lazy(ObservablePromise<NFTPriceStatus>)
}

typealias SimilarTokensGetter = (UInt) -> [UInt]?
typealias RarityRankGetter = (UInt) -> UInt?
struct CollectionInfo {
  let address: String
  let url1: String
  let url2: String
  let url3: String
  let url4: String
  let name: String
  let webLink: URL
  let themeColor:Color
  let themeLabelColor:Color
  let subThemeColor:Color
  let collectionColor:Color
  let disableRecentTrades : Bool
  let blur:CGFloat
  let samplePadding:CGFloat
  let similarTokens : SimilarTokensGetter
  let rarityRank : RarityRankGetter
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

let CryptoPunks_nearestTokens : [[UInt]] = load("CryptoPunks_nearestTokens.json")
let CryptoPunks_rarityRanks : [UInt] = load("CryptoPunks_rarityRanks.json")

let AsciiPunks_nearestTokens : [[UInt]] = load("AsciiPunks_nearestTokens.json")
let AsciiPunks_rarityRanks : [UInt] = load("AsciiPunks_rarityRanks.json")

let cryptoPunksContract =  CryptoPunksContract();
let cryptoKittiesContract = CryptoKittiesAuction();
let asciiPunksContract = AsciiPunksContract();
let autoGlyphsContract = AutoglyphsContract()

let CompositeCollection = CompositeRecentTradesObject([
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:cryptoPunksContract.contractAddressHex,
      url1:SAMPLE_PUNKS[0],
      url2:SAMPLE_PUNKS[1],
      url3:SAMPLE_PUNKS[2],
      url4:SAMPLE_PUNKS[3],
      name:"CryptoPunks",
      webLink: URL(string:"https://www.larvalabs.com/cryptopunks")!,
      themeColor:Color.yellow,
      themeLabelColor:Color.systemBackground,
      subThemeColor: /* FFB61E */ Color(red: 255/255, green: 182/255, blue: 30/255),
      collectionColor:Color.yellow,
      disableRecentTrades:false,
      blur:0,
      samplePadding:10,
      similarTokens : { tokenId in CryptoPunks_nearestTokens[safe:Int(tokenId)] },
      rarityRank : { tokenId in CryptoPunks_rarityRanks[safe:Int(tokenId)] }),
    contract:cryptoPunksContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:cryptoKittiesContract.contractAddressHex,
      url1:SAMPLE_KITTIES[0],
      url2:SAMPLE_KITTIES[1],
      url3:SAMPLE_KITTIES[2],
      url4:SAMPLE_KITTIES[3],
      name:"CryptoKitties",
      webLink: URL(string:"https://www.cryptokitties.co")!,
      themeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
      themeLabelColor:Color.systemBackground,
      subThemeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
      collectionColor:/* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
      disableRecentTrades:true,
      blur:0,samplePadding:0,
      similarTokens: { tokenId in nil },
      rarityRank : { tokenId in nil }),
    contract:cryptoKittiesContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:asciiPunksContract.contractAddressHex,
      url1:SAMPLE_ASCII_PUNKS[0],
      url2:SAMPLE_ASCII_PUNKS[1],
      url3:SAMPLE_ASCII_PUNKS[2],
      url4:SAMPLE_ASCII_PUNKS[3],
      name:"AsciiPunks",
      webLink: URL(string:"https://asciipunks.com")!,
      themeColor:Color.label,
      themeLabelColor:Color.systemBackground,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      blur:0,
      samplePadding:10,
      similarTokens : { tokenId in AsciiPunks_nearestTokens[safe:Int(tokenId)] },
      rarityRank : { tokenId in AsciiPunks_rarityRanks[safe:Int(tokenId)] }),
    contract:asciiPunksContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:autoGlyphsContract.contractAddressHex,
      url1:SAMPLE_AUTOGLYPHS[0],
      url2:SAMPLE_AUTOGLYPHS[1],
      url3:SAMPLE_AUTOGLYPHS[2],
      url4:SAMPLE_AUTOGLYPHS[3],
      name:"Autoglyphs",
      webLink: URL(string:"https://www.larvalabs.com/autoglyphs")!,
      themeColor:Color.label,
      themeLabelColor:Color.gray,
      subThemeColor:Color.label,
      collectionColor:Color.white,
      disableRecentTrades:false,
      blur:0,
      samplePadding:10,
      similarTokens: { tokenId in nil },
      rarityRank : { tokenId in nil }),
    contract:autoGlyphsContract),
]
)

let SampleToken = NFT(
  address: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb",
  tokenId: 340, name: "CryptoPunks",
  media: .image(MediaImageEager(URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk0385.png")!)))

let SampleCollection = CompositeCollection.collections[0]


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

let COLLECTIONS : [Collection] = CompositeCollection.collections

struct CollectionsFactory {
  
  let collections : [String : Collection] = Dictionary(uniqueKeysWithValues: COLLECTIONS.map{ ($0.info.address,$0) })
  
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

extension String {
  /*
   Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
   - Parameter length: Desired maximum lengths of a string
   - Parameter trailing: A 'String' that will be appended after the truncation.
   
   - Returns: 'String' object.
   */
  func trunc(length: Int, trailing: String = "…") -> String {
    return (self.count > length) ? self.prefix(length) + trailing : self
  }
  
  func deletingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    return String(self.dropFirst(prefix.count))
  }
}

let SAMPLE_WALLET_ADDRESS = try! EthereumAddress(
  hex: "0x208b82b04449cd51803fae4b1561450ba13d9510",
  eip55:false)

enum UserDefaultsKeys : String {
  case walletAddress = "walletAddress"
  case favoritesDict = "favoritesDict"
}
