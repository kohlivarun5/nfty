//
//  CoreCollections.swift
//  NFTY
//
//  Created by Varun Kohli on 6/22/21.
//

import Foundation
import SwiftUI
import Web3

let cryptoPunksContract =  CryptoPunksContract();
let cryptoKittiesContract = CryptoKittiesAuction();
let asciiPunksContract = AsciiPunksContract();
let autoGlyphsContract = AutoglyphsContract()
let baycContract = IpfsCollectionContract(name:"BAYC",address: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D")
let fameLadyContract = FameLadySquad_Contract()
let CRHDL_Contract = IpfsCollectionContract(name: "CryptoHodlers",address: "0xe12a2A0Fb3fB5089A498386A734DF7060c1693b8")
let CROWNS_Contract = IpfsCollectionContract(name: "Crowns",address: "0x42e8CB3b99658EeB70Af7eD97a3f21d8349b433E")
let CCB_Contract = UrlCollectionContract(name: "NFTokers", address: "0x80a4B80C653112B789517eb28aC111519b608b19", baseUri: "https://api.cryptocannabisclub.com/image/")

let Birdhouse_Contract = UrlCollectionContract(name: "TheBirdHouse", address: "0x149915F1FD17fe5899ADac2542Be90690eD8A526", baseUri: "https://tbh-data.s3.amazonaws.com/final/images/")

let CYPHER_CITY_Contract = IpfsCollectionContract(
  name: "Cypher City",
  address: "0x00C396383400a1EF2eB401052dBF5d989B2da481")

let CoolCats_Contract = IpfsCollectionContract(name: "CoolCats",address: "0x1A92f7381B9F03921564a437210bB9396471050C")

let DeadFellaz_Contract = IpfsCollectionContract(name: "DeadFellaz",address: "0x2acAb3DEa77832C09420663b0E1cB386031bA17B")

let DJs_Contract = IpfsWithOpenSea(name: "DJENERATES",address: "0x7d05c8D8cC1baC936eA09308a9E94823986f8321")

let ON1_Force_Contract = IpfsWithOpenSea(name: "0N1 Force",address: "0x3bf2922f4520a8BA0c2eFC3D2a1539678DaD5e9D")

let Craniums_Contract = IpfsWithOpenSea(name: "WickedCraniums",address: "0x85f740958906b317de6ed79663012859067E745B")

let WABC_Contract = IpfsWithOpenSea(name: "Wicked Apes",address: "0xbe6e3669464E7dB1e1528212F0BfF5039461CB82")

let CompositeCollection = CompositeRecentTradesObject([
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:cryptoPunksContract.contractAddressHex,
      sample:SAMPLE_PUNKS[0],
      name:"CryptoPunks",
      webLink: URL(string:"https://www.larvalabs.com/cryptopunks")!,
      themeColor:Color.yellow,
      themeLabelColor:Color.systemBackground,
      subThemeColor: /* FFB61E */ Color(red: 255/255, green: 182/255, blue: 30/255),
      collectionColor:Color.yellow,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(label:"Punks",nearestTokensFileName:"CryptoPunks_nearestTokens.json"),
      rarityRanking : RarityRankingImpl(CryptoPunks_rarityRanks)
    ),
    contract:cryptoPunksContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:autoGlyphsContract.contractAddressHex,
      sample:SAMPLE_AUTOGLYPHS[0],
      name:"Autoglyphs",
      webLink: URL(string:"https://www.larvalabs.com/autoglyphs")!,
      themeColor:Color.label,
      themeLabelColor:Color.gray,
      subThemeColor:Color.label,
      collectionColor:Color.white,
      disableRecentTrades:false,
      similarTokens: nil,
      rarityRanking: nil
    ),
    contract:autoGlyphsContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:asciiPunksContract.contractAddressHex,
      sample:SAMPLE_ASCII_PUNKS[0],
      name:"AsciiPunks",
      webLink: URL(string:"https://asciipunks.com")!,
      themeColor:Color.label,
      themeLabelColor:Color.systemBackground,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Punks",
        nearestTokensFileName:"AsciiPunks_nearestTokens.json",
        propertiesJsonFileName:"AsciiPunks_attributeScores.json"),
      rarityRanking : RarityRankingImpl(AsciiPunks_rarityRanks)
    ),
    contract:asciiPunksContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:baycContract.contractAddressHex,
      sample:SAMPLE_BAYC[0],
      name:"BAYC",
      webLink: URL(string:"https://boredapeyachtclub.com/#/")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Apes",
        nearestTokensFileName:"BoredApeYachtClub_nearestTokens.json",
        propertiesJsonFileName:"BAYC_attributeScores.json"),
      rarityRanking : RarityRankingImpl(BAYC_rarityRanks)
    ),
    contract:baycContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:fameLadyContract.contractAddressHex,
      sample:SAMPLE_FLS[0],
      name:"FameLadySquad",
      webLink: URL(string:"https://fameladysquad.com")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Ladies",
        nearestTokensFileName:"FameLadySquad_nearestTokens.json",
        propertiesJsonFileName:"FameLadySquad_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(FLS_rarityRanks)
    ),
    contract:fameLadyContract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:CRHDL_Contract.contractAddressHex,
      sample:SAMPLE_CRHDL[0],
      name:CRHDL_Contract.name,
      webLink: URL(string:"https://cryptohodlers.io/")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Hodlers",
        nearestTokensFileName:"CryptoHodlers_nearestTokens.json",
        propertiesJsonFileName:"CryptoHodlers_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(CRHDL_rarityRanks)
    ),
    contract:CRHDL_Contract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:CROWNS_Contract.contractAddressHex,
      sample:SAMPLE_CROWNS[0],
      name:CROWNS_Contract.name,
      webLink: URL(string:"https://fameladysquad.com")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens: nil,
      rarityRanking: nil
    ),
    contract:CROWNS_Contract),
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:CYPHER_CITY_Contract.contractAddressHex,
      sample:SAMPLE_CYPHER[0],
      name:CYPHER_CITY_Contract.name,
      webLink: URL(string:"https://cyphercity.io/home")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Cyphers",
        nearestTokensFileName:"CypherCity_nearestTokens.json",
        propertiesJsonFileName:"CypherCity_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(CypherCity_rarityRanks)
    ),
    contract:CYPHER_CITY_Contract),
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:CCB_Contract.contractAddressHex,
      sample:SAMPLE_CCB[0],
      name:CCB_Contract.name,
      webLink: URL(string:"https://cryptocannabisclub.com/")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"NFTokers",
        nearestTokensFileName:"CryptoCannabisClub_nearestTokens.json",
        propertiesJsonFileName:"CryptoCannabisClub_attributeScores.json"),
      rarityRanking : RarityRankingImpl(CCD_rarityRanks)
    ),
    contract:CCB_Contract),
  
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:CoolCats_Contract.contractAddressHex,
      sample:SAMPLE_COOL_CATS[0],
      name:CoolCats_Contract.name,
      webLink: URL(string:"https://www.coolcatsnft.com/")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Cats",
        nearestTokensFileName:"CoolCats_nearestTokens.json",
        propertiesJsonFileName:"CoolCats_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(CoolCats_rarityRanks)
    ),
    contract:CoolCats_Contract),
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:DeadFellaz_Contract.contractAddressHex,
      sample:SAMPLE_DEAD_FELLAZ[0],
      name:DeadFellaz_Contract.name,
      webLink: URL(string:"https://www.deadfellaz.io")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Fellaz",
        nearestTokensFileName:"DeadFellaz_nearestTokens.json",
        propertiesJsonFileName:"DeadFellaz_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(DeadFellaz_rarityRanks)
    ),
    contract:DeadFellaz_Contract),
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:Birdhouse_Contract.contractAddressHex,
      sample:SAMPLE_TBH[0],
      name:Birdhouse_Contract.name,
      webLink: URL(string:"https://thebirdhouse.app")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Birds",
        nearestTokensFileName:"BirdHouse_nearestTokens.json",
        propertiesJsonFileName:"BirdHouse_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(BirdHouse_rarityRanks)
    ),
    contract:Birdhouse_Contract),
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:ON1_Force_Contract.contractAddressHex,
      sample:"SAMPLE_0N1",
      name:ON1_Force_Contract.name,
      webLink: URL(string:"https://www.0n1force.com/")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : nil/*SimilarTokensGetter(
       label:"Birds",
       nearestTokensFileName:"BirdHouse_nearestTokens.json",
       propertiesJsonFileName:"BirdHouse_attributeScores.json"
       )*/,
      rarityRanking : nil//RarityRankingImpl(BirdHouse_rarityRanks)
    ),
    contract:ON1_Force_Contract),
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:DJs_Contract.contractAddressHex,
      sample:"SAMPLE_DJ",
      name:DJs_Contract.name,
      webLink: URL(string:"https://djenerates.com/")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"DJENERATES",
        nearestTokensFileName:"DJENERATES_nearestTokens.json",
        propertiesJsonFileName:"DJENERATES_attributeScores.json"),
      rarityRanking : RarityRankingImpl(load("DJENERATES_rarityRanks.json")) //TODO : Update on full mint
    ),
    contract:DJs_Contract),
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:WABC_Contract.contractAddressHex,
      sample:"SAMPLE_WABC",
      name:WABC_Contract.name,
      webLink: URL(string:"https://wickedapes.com")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Apes",
        nearestTokensFileName:"WickedApes_nearestTokens.json",
        propertiesJsonFileName:"WickedApes_attributeScores.json"),
      rarityRanking : RarityRankingImpl(load("WickedApes_rarityRanks.json"))
    ),
    contract:WABC_Contract),
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:Craniums_Contract.contractAddressHex,
      sample:"SAMPLE_WICKED_CRANIUM",
      name:Craniums_Contract.name,
      webLink: URL(string:"https://wickedcranium.com")!,
      themeColor:Color.black,
      themeLabelColor:Color.white,
      subThemeColor:Color.label,
      collectionColor:Color.black,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Craniums",
        nearestTokensFileName:"Craniums_nearestTokens.json",
        propertiesJsonFileName:"Craniums_attributeScores.json"),
      rarityRanking : RarityRankingImpl(load("Craniums_rarityRanks.json"))
    ),
    contract:Craniums_Contract),
  
  CompositeRecentTradesObject.CollectionInitializer(
    info:CollectionInfo(
      address:cryptoKittiesContract.contractAddressHex,
      sample:SAMPLE_KITTIES[0],
      name:"CryptoKitties",
      webLink: URL(string:"https://www.cryptokitties.co")!,
      themeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
      themeLabelColor:Color.systemBackground,
      subThemeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
      collectionColor:/* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
      disableRecentTrades:true,
      similarTokens: nil,
      rarityRanking: nil
    ),
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
