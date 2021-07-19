//
//  CoreCollections.swift
//  NFTY
//
//  Created by Varun Kohli on 6/22/21.
//

import Foundation
import SwiftUI
import Web3

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
      similarTokens : SimilarTokensGetter(label:"Punks") { tokenId in CryptoPunks_nearestTokens[safe:Int(tokenId)] },
      rarityRank : { tokenId in CryptoPunks_rarityRanks[safe:Int(tokenId)] }),
    contract:cryptoPunksContract),
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
      similarTokens: nil,
      rarityRank : { tokenId in nil }),
    contract:autoGlyphsContract),
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
      similarTokens : SimilarTokensGetter(label:"Punks")  { tokenId in AsciiPunks_nearestTokens[safe:Int(tokenId)] },
      rarityRank : { tokenId in AsciiPunks_rarityRanks[safe:Int(tokenId)] }),
    contract:asciiPunksContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:baycContract.contractAddressHex,
      url1:SAMPLE_BAYC[0],
      url2:SAMPLE_BAYC[1],
      url3:SAMPLE_BAYC[2],
      url4:SAMPLE_BAYC[3],
      name:"BoredApeYachtClub",
      webLink: URL(string:"https://boredapeyachtclub.com/#/")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      blur:0,
      samplePadding:15,
      similarTokens : SimilarTokensGetter(label:"Apes")  { tokenId in BAYC_nearestTokens[safe:Int(tokenId)] },
      rarityRank : { tokenId in BAYC_rarityRanks[safe:Int(tokenId)] }),
    contract:baycContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:fameLadyContract.contractAddressHex,
      url1:SAMPLE_FLS[0],
      url2:SAMPLE_FLS[1],
      url3:SAMPLE_FLS[2],
      url4:SAMPLE_FLS[3],
      name:"FameLadySquad",
      webLink: URL(string:"https://fameladysquad.com")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      blur:0,
      samplePadding:15,
      similarTokens : SimilarTokensGetter(label:"Ladies")  { tokenId in FLS_nearestTokens[safe:Int(tokenId)] },
      rarityRank : { tokenId in FLS_rarityRanks[safe:Int(tokenId)] }),
    contract:fameLadyContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:CRHDL_Contract.contractAddressHex,
      url1:SAMPLE_CRHDL[0],
      url2:SAMPLE_CRHDL[1],
      url3:SAMPLE_CRHDL[2],
      url4:SAMPLE_CRHDL[3],
      name:CRHDL_Contract.name,
      webLink: URL(string:"https://cryptohodlers.io/")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      blur:0,
      samplePadding:15,
      similarTokens: nil,
      rarityRank : { tokenId in nil }),
    contract:CRHDL_Contract),
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
      similarTokens: nil,
      rarityRank : { tokenId in nil }),
    contract:cryptoKittiesContract),
]
)

let SampleToken = NFT(
  address: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb",
  tokenId: 340, name: "CryptoPunks",
  media: .image(MediaImageEager(URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk0385.png")!)))

let SampleCollection = CompositeCollection.collections[0]

let COLLECTIONS : [Collection] = CompositeCollection.collections

struct CollectionsFactory {
  
  let collections : [String : Collection] = Dictionary(uniqueKeysWithValues: COLLECTIONS.map{ ($0.info.address,$0) })
  
  func getByAddress(_ address:String) -> Collection? {
    return collections[address]
  }
  
}

let collectionsFactory = CollectionsFactory()

let SAMPLE_WALLET_ADDRESS = try! EthereumAddress(
  hex: "0x208b82b04449cd51803fae4b1561450ba13d9510",
  eip55:false)

enum CloudDefaultStorageKeys : String {
  case walletAddress = "walletAddress"
  case favoritesDict = "favoritesDict"
  case friendsDict = "friendsDict"
}

class NftOwnerTokens : ObservableObject {
  @Published var tokens: [NFTWithLazyPrice] = []
  
  enum LoadingState {
    case notLoaded
    case loading
    case loaded
  }
  @Published var state : LoadingState = .notLoaded
  
  let ownerAddress : EthereumAddress
  private let contracts : [ContractInterface]
  
  private var pendingCount = 0
  
  init(ownerAddress:EthereumAddress) {
    self.ownerAddress = ownerAddress
    self.contracts = COLLECTIONS.map { $0.data.contract }
  }
  
  func load() {
    if (state != .notLoaded) { return }
    
    state = .loading
    contracts.forEach { contract in
      contract.getOwnerTokens(
        address:ownerAddress,
        
        onDone: {
          DispatchQueue.main.async {
            self.state = .loaded
          }
        }
      ) { token in
        DispatchQueue.main.async {
          self.tokens.append(token)
        }
      }
    }
  }
  
}

var OwnerTokensCache : [EthereumAddress:NftOwnerTokens] = [:]
func getOwnerTokens(_ address:EthereumAddress) -> NftOwnerTokens {
  switch OwnerTokensCache[address] {
  case .some(let tokens):
    return tokens
  case .none:
    OwnerTokensCache[address] = NftOwnerTokens(ownerAddress: address)
    return OwnerTokensCache[address]!
  }
}
