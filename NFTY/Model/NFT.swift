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
  
  struct IpfsImage : Codable {
    let data : Data
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

let SAMPLE_BAYC : [String] = [
  "SampleBAYC1",
  "SampleBAYC2",
  "SampleBAYC3",
  "SampleBAYC4"
]

let CryptoPunks_nearestTokens : [[UInt]] = load("CryptoPunks_nearestTokens.json")
let CryptoPunks_rarityRanks : [UInt] = load("CryptoPunks_rarityRanks.json")

let AsciiPunks_nearestTokens : [[UInt]] = load("AsciiPunks_nearestTokens.json")
let AsciiPunks_rarityRanks : [UInt] = load("AsciiPunks_rarityRanks.json")

let cryptoPunksContract =  CryptoPunksContract();
let cryptoKittiesContract = CryptoKittiesAuction();
let asciiPunksContract = AsciiPunksContract();
let autoGlyphsContract = AutoglyphsContract()
let baycContract = BAYC_Contract()
