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
let baycContract = IpfsCollectionContract(
  name:"BAYC",
  address: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D",
  indicativePriceSource: .openSea)

let fameLadyContract = FameLadySquad_Contract()
let CRHDL_Contract = IpfsCollectionContract(
  name: "CryptoHodlers",
  address: "0xe12a2A0Fb3fB5089A498386A734DF7060c1693b8",
  indicativePriceSource: .openSea)

let CROWNS_Contract = IpfsCollectionContract(
  name: "Crowns",
  address: "0x42e8CB3b99658EeB70Af7eD97a3f21d8349b433E",
  indicativePriceSource: .openSea)

let CCB_Contract = UrlCollectionContract(
  name: "NFTokers",
  address: "0x80a4B80C653112B789517eb28aC111519b608b19",
  tokenUri: { "https://api.cryptocannabisclub.com/image/\($0)"},
  indicativePriceSource: .openSea)

let Birdhouse_Contract = UrlCollectionContract(
  name: "TheBirdHouse",
  address: "0x149915F1FD17fe5899ADac2542Be90690eD8A526",
  tokenUri: { "https://tbh-data.s3.amazonaws.com/final/images/\($0)"},
  indicativePriceSource: .openSea)

let CYPHER_CITY_Contract = IpfsCollectionContract(
  name: "Cypher City",
  address: "0x00C396383400a1EF2eB401052dBF5d989B2da481",
  indicativePriceSource: .openSea)

let CoolCats_Contract = IpfsCollectionContract(
  name: "CoolCats",
  address: "0x1A92f7381B9F03921564a437210bB9396471050C",
  indicativePriceSource: .swapPoolContract(
    pool:"0x0225e940deecc32a8d7c003cfb7dae22af18460c",
    vault:"0x114f1388fAB456c4bA31B1850b244Eedcd024136"
  )
)

let DeadFellaz_Contract = IpfsCollectionContract(
  name: "DeadFellaz",
  address: "0x2acAb3DEa77832C09420663b0E1cB386031bA17B",
  indicativePriceSource: .openSea
)

let DJs_Contract = IpfsWithOpenSea(
  name: "DJENERATES",
  address: "0x7d05c8D8cC1baC936eA09308a9E94823986f8321",
  indicativePriceSource: .openSea
)

let ON1_Force_Contract = IpfsCollectionContract(
  name: "0N1 Force",
  address: "0x3bf2922f4520a8BA0c2eFC3D2a1539678DaD5e9D",
  indicativePriceSource: .openSea
)

let Craniums_Contract = IpfsCollectionContract(
  name: "WickedCraniums",
  address: "0x85f740958906b317de6ed79663012859067E745B",
  indicativePriceSource: .openSea)

let WABC_Contract = IpfsCollectionContract(
  name: "Wicked Apes",
  address: "0xbe6e3669464E7dB1e1528212F0BfF5039461CB82",
  indicativePriceSource: .openSea)

let MAYC_Contract = IpfsCollectionContract(
  name: "MAYC",
  address: "0x60E4d786628Fea6478F785A6d7e704777c86a7c6",
  indicativePriceSource: .swapPoolContract(
    pool:"0xc5817a4c5e8ec6488c9a26c6862ff3060757b498",
    vault:"0x94c9cEb2F9741230FAD3a62781b27Cc79a9460d4"
  )
)

let KILLAZ_Contract = UrlCollectionContract(
  name: "KILLAz",
  address: "0x21850dCFe24874382B12d05c5B189F5A2ACF0E5b",
  tokenUri: { "https://killaznft.com/api/images/\($0)"},
  indicativePriceSource: .openSea)

let ABS_Contract = IpfsCollectionContract(
  name: "AdamBombSquad",
  address: "0x7AB2352b1D2e185560494D5e577F9D3c238b78C5",
  indicativePriceSource: .swapPoolContract(
    pool:"0xe3d7e2d92a5158229921c56fb23421093d475bfb",
    vault:"0x210f4A59097c5E10eC67DB9b03cF35332A9aa0Cf"
  )
)

let DADS_Contract = IpfsCollectionContract(
  name: "CryptoDads",
  address: "0xECDD2F733bD20E56865750eBcE33f17Da0bEE461",
  indicativePriceSource: .openSea)

let LIONS_Contract = IpfsCollectionContract(
  name: "LazyLions",
  address: "0x8943C7bAC1914C9A7ABa750Bf2B6B09Fd21037E0",
  indicativePriceSource: .openSea)

let MORIES_Contract = IpfsCollectionContract(
  name: "CryptoMories",
  address: "0x1a2F71468F656E97c2F86541E57189F59951efe7",
  indicativePriceSource: .swapPoolContract(
    pool: "0x10e5b7e68febf9014e08e2b38894237a45fd32c2",
    vault: "0x7269c9AAA5eD95f0CC9DC15ff19A4596308c889C"))

let JUNGLE_FREAKS_Contract = IpfsCollectionContract(
  name: "JungleFreaks",
  address: "0x7E6Bc952d4b4bD814853301bEe48E99891424de0",
  indicativePriceSource: .openSea)

let DOODLES_Contract = IpfsCollectionContract(
  name: "Doodles",
  address: "0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e",
  indicativePriceSource: .swapPoolContract(
    pool:"0x60aacb5e507d41a95c9109cc6778fb0b94227616",
    vault:"0x2F131C4DAd4Be81683ABb966b4DE05a549144443"
  )
)

let FRWC_Contract = IpfsCollectionContract(
  name: "FRWC",
  address: "0x521f9C7505005CFA19A8E5786a9c3c9c9F5e6f42",
  indicativePriceSource: .swapPoolContract(
    pool:"0x0a2f9b5360b5c7b6d3ce826971425b3b8b766519",
    vault:"0x87931E7AD81914e7898d07c68F145fC0A553D8Fb"
  )
)

let PHUNKS_Contract = PhunksContract()

let GBLOCKS_Contract = GenesisBlockContract(
  name: "GenesisBlocks",
  address: "0x26b925EEf82525f514C0414DB5cF65953d30a4CA")

let ZUNKS_Contract = ZunksContract(
  name: "CryptoZunks",
  address: "0x031920cc2D9F5c10B444FD44009cd64F829E7be2")

let PUDGY_Contract = IpfsCollectionContract(
  name: "PudgyPenguins",
  address: "0xBd3531dA5CF5857e7CfAA92426877b022e612cf8",
  indicativePriceSource: .swapPoolContract(
    pool:"0x5d472c9edece12a75ed7c0584dd02407cb5b47da",
    vault:"0xAbeA7663c472648d674bd3403D94C858dFeEF728")
)

let SSFU_Contract = IpfsCollectionContract(
  name: "SSFU",
  address: "0x4503e3C58377a9d2A9ec3c9eD42a8a6a241Cb4e2",
  indicativePriceSource: .openSea)

let ILLUMINATI_Contract = IpfsCollectionContract(
  name: "Illuminati",
  address: "0x26BAdF693F2b103B021c670c852262b379bBBE8A",
  indicativePriceSource: .openSea)

let CHUBBI_FRENS_Contract = IpfsCollectionContract(
  name: "Chubbiverse Frens",
  address: "0x42f1654B8eeB80C96471451B1106b63D0B1a9fe1",
  indicativePriceSource: .openSea)

let CompositeCollection = CompositeRecentTradesObject([
  Collection(
    info:CollectionInfo(
      address:cryptoPunksContract.contractAddressHex,
      sample:SAMPLE_PUNKS[0],
      name:"CryptoPunks",
      webLink: URL(string:"https://www.larvalabs.com/cryptopunks")!,
      themeColor:Color.yellow,
      themeLabelColor:Color.systemBackground,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Punks",
        nearestTokensFileName:"CryptoPunks_nearestTokens.json",
        propertiesJsonFileName:"CryptoPunks_attributeScores.json"),
      rarityRanking : RarityRankingImpl(CryptoPunks_rarityRanks)
    ),
    contract:cryptoPunksContract),
  Collection(
    info:CollectionInfo(
      address:autoGlyphsContract.contractAddressHex,
      sample:SAMPLE_AUTOGLYPHS[0],
      name:"Autoglyphs",
      webLink: URL(string:"https://www.larvalabs.com/autoglyphs")!,
      themeColor:Color.label,
      themeLabelColor:Color.gray,
      disableRecentTrades:false,
      similarTokens: nil,
      rarityRanking: nil
    ),
    contract:autoGlyphsContract),
  Collection(
    info:CollectionInfo(
      address:asciiPunksContract.contractAddressHex,
      sample:SAMPLE_ASCII_PUNKS[0],
      name:"AsciiPunks",
      webLink: URL(string:"https://asciipunks.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Punks",
        nearestTokensFileName:"AsciiPunks_nearestTokens.json",
        propertiesJsonFileName:"AsciiPunks_attributeScores.json"),
      rarityRanking : RarityRankingImpl(AsciiPunks_rarityRanks)
    ),
    contract:asciiPunksContract),
  Collection(
    info:CollectionInfo(
      address:baycContract.contractAddressHex,
      sample:SAMPLE_BAYC[0],
      name:"BAYC",
      webLink: URL(string:"https://boredapeyachtclub.com/#/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Apes",
        nearestTokensFileName:"BoredApeYachtClub_nearestTokens.json",
        propertiesJsonFileName:"BAYC_attributeScores.json"),
      rarityRanking : RarityRankingImpl(BAYC_rarityRanks)
    ),
    contract:baycContract),
  
  Collection(
    info:CollectionInfo(
      address:MAYC_Contract.contractAddressHex,
      sample:"SAMPLE_MAYC",
      name:MAYC_Contract.name,
      webLink: URL(string:"https://boredapeyachtclub.com/#/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Mutants",
        nearestTokensFileName:"MutantApes_nearestTokens.json",
        propertiesJsonFileName:"MutantApes_attributeScores.json"),
      rarityRanking : RarityRankingImpl(load("MutantApes_rarityRanks.json"))
    ),
    contract:MAYC_Contract),
  Collection(
    info:CollectionInfo(
      address:fameLadyContract.contractAddressHex,
      sample:SAMPLE_FLS[0],
      name:"FameLadySquad",
      webLink: URL(string:"https://fameladysquad.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Ladies",
        nearestTokensFileName:"FameLadySquad_nearestTokens.json",
        propertiesJsonFileName:"FameLadySquad_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(FLS_rarityRanks)
    ),
    contract:fameLadyContract),
  Collection(
    info:CollectionInfo(
      address:CRHDL_Contract.contractAddressHex,
      sample:SAMPLE_CRHDL[0],
      name:CRHDL_Contract.name,
      webLink: URL(string:"https://cryptohodlers.io/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Hodlers",
        nearestTokensFileName:"CryptoHodlers_nearestTokens.json",
        propertiesJsonFileName:"CryptoHodlers_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(CRHDL_rarityRanks)
    ),
    contract:CRHDL_Contract),
  Collection(
    info:CollectionInfo(
      address:CROWNS_Contract.contractAddressHex,
      sample:SAMPLE_CROWNS[0],
      name:CROWNS_Contract.name,
      webLink: URL(string:"https://fameladysquad.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens: nil,
      rarityRanking: nil
    ),
    contract:CROWNS_Contract),
  Collection(
    info:CollectionInfo(
      address:CYPHER_CITY_Contract.contractAddressHex,
      sample:SAMPLE_CYPHER[0],
      name:CYPHER_CITY_Contract.name,
      webLink: URL(string:"https://cyphercity.io/home")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Cyphers",
        nearestTokensFileName:"CypherCity_nearestTokens.json",
        propertiesJsonFileName:"CypherCity_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(CypherCity_rarityRanks)
    ),
    contract:CYPHER_CITY_Contract),
  
  Collection(
    info:CollectionInfo(
      address:CCB_Contract.contractAddressHex,
      sample:SAMPLE_CCB[0],
      name:CCB_Contract.name,
      webLink: URL(string:"https://cryptocannabisclub.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"NFTokers",
        nearestTokensFileName:"CryptoCannabisClub_nearestTokens.json",
        propertiesJsonFileName:"CryptoCannabisClub_attributeScores.json"),
      rarityRanking : RarityRankingImpl(CCD_rarityRanks)
    ),
    contract:CCB_Contract),
  Collection(
    info:CollectionInfo(
      address:CoolCats_Contract.contractAddressHex,
      sample:SAMPLE_COOL_CATS[0],
      name:CoolCats_Contract.name,
      webLink: URL(string:"https://www.coolcatsnft.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Cats",
        nearestTokensFileName:"CoolCats_nearestTokens.json",
        propertiesJsonFileName:"CoolCats_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(CoolCats_rarityRanks)
    ),
    contract:CoolCats_Contract),
  
  Collection(
    info:CollectionInfo(
      address:ABS_Contract.contractAddressHex,
      sample:"SAMPLE_ABS",
      name:ABS_Contract.name,
      webLink: URL(string:"https://abs.thehundreds.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Bombs",
        nearestTokensFileName:"Bombs_nearestTokens.json"
        //,propertiesJsonFileName:"Bombs_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(load("Bombs_rarityRanks.json"))
    ),
    contract:ABS_Contract),
  Collection(
    info:CollectionInfo(
      address:LIONS_Contract.contractAddressHex,
      sample:"SAMPLE_LAZY_LION",
      name:LIONS_Contract.name,
      webLink: URL(string:"https://www.lazylionsnft.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Lions",
        nearestTokensFileName:"LazyLions_nearestTokens.json",
        propertiesJsonFileName:"LazyLions_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(load("LazyLions_rarityRanks.json"))
    ),
    contract:LIONS_Contract),
  Collection(
    info:CollectionInfo(
      address:DADS_Contract.contractAddressHex,
      sample:"SAMPLE_DAD",
      name:DADS_Contract.name,
      webLink: URL(string:"https://www.cryptodadsnft.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Dads",
        nearestTokensFileName:"Dads_nearestTokens.json",
        propertiesJsonFileName:"Dads_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(load("Dads_rarityRanks.json"))
    ),
    contract:DADS_Contract),
  Collection(
    info:CollectionInfo(
      address:GBLOCKS_Contract.contractAddressHex,
      sample:"SAMPLE_GBLOCK",
      name:GBLOCKS_Contract.name,
      webLink: URL(string:"https://genesisblocks.art")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Blocks",
        nearestTokensFileName:nil,
        propertiesJsonFileName:"GenesisBlocks_attributeScores.json"
      ),
      rarityRanking : nil//RarityRankingImpl(load("Dads_rarityRanks.json"))
    ),
    contract:GBLOCKS_Contract),
  Collection(
    info:CollectionInfo(
      address:DeadFellaz_Contract.contractAddressHex,
      sample:SAMPLE_DEAD_FELLAZ[0],
      name:DeadFellaz_Contract.name,
      webLink: URL(string:"https://www.deadfellaz.io")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Fellaz",
        nearestTokensFileName:"DeadFellaz_nearestTokens.json",
        propertiesJsonFileName:"DeadFellaz_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(DeadFellaz_rarityRanks)
    ),
    contract:DeadFellaz_Contract),
  Collection(
    info:CollectionInfo(
      address:Birdhouse_Contract.contractAddressHex,
      sample:SAMPLE_TBH[0],
      name:Birdhouse_Contract.name,
      webLink: URL(string:"https://thebirdhouse.app")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Birds",
        nearestTokensFileName:"BirdHouse_nearestTokens.json",
        propertiesJsonFileName:"BirdHouse_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(BirdHouse_rarityRanks)
    ),
    contract:Birdhouse_Contract),
  Collection(
    info:CollectionInfo(
      address:ON1_Force_Contract.contractAddressHex,
      sample:"SAMPLE_0N1",
      name:ON1_Force_Contract.name,
      webLink: URL(string:"https://www.0n1force.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : nil/*SimilarTokensGetter(
                          label:"Birds",
                          nearestTokensFileName:"BirdHouse_nearestTokens.json",
                          propertiesJsonFileName:"BirdHouse_attributeScores.json"
                          )*/,
      rarityRanking : nil//RarityRankingImpl(BirdHouse_rarityRanks)
    ),
    contract:ON1_Force_Contract),
  Collection(
    info:CollectionInfo(
      address:DJs_Contract.contractAddressHex,
      sample:"SAMPLE_DJ",
      name:DJs_Contract.name,
      webLink: URL(string:"https://djenerates.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"DJENERATES",
        nearestTokensFileName:"DJENERATES_nearestTokens.json",
        propertiesJsonFileName:"DJENERATES_attributeScores.json"),
      rarityRanking : RarityRankingImpl(load("DJENERATES_rarityRanks.json"))
    ),
    contract:DJs_Contract),
  Collection(
    info:CollectionInfo(
      address:WABC_Contract.contractAddressHex,
      sample:"SAMPLE_WABC",
      name:WABC_Contract.name,
      webLink: URL(string:"https://wickedapes.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Apes",
        nearestTokensFileName:"WickedApes_nearestTokens.json",
        propertiesJsonFileName:"WickedApes_attributeScores.json"),
      rarityRanking : RarityRankingImpl(load("WickedApes_rarityRanks.json"))
    ),
    contract:WABC_Contract),
  Collection(
    info:CollectionInfo(
      address:Craniums_Contract.contractAddressHex,
      sample:"SAMPLE_WICKED_CRANIUM",
      name:Craniums_Contract.name,
      webLink: URL(string:"https://wickedcranium.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Craniums",
        nearestTokensFileName:"Craniums_nearestTokens.json",
        propertiesJsonFileName:"Craniums_attributeScores.json"),
      rarityRanking : RarityRankingImpl(load("Craniums_rarityRanks.json"))
    ),
    contract:Craniums_Contract),
  Collection(
    info:CollectionInfo(
      address:KILLAZ_Contract.contractAddressHex,
      sample:"SAMPLE_KILLAZ",
      name:KILLAZ_Contract.name,
      webLink: URL(string:"https://crashcitykillaz.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Killaz",
        nearestTokensFileName:"Killaz_nearestTokens.json",
        propertiesJsonFileName:"Killaz_attributeScores.json"),
      rarityRanking : RarityRankingImpl(load("Killaz_rarityRanks.json"))
    ),
    contract:KILLAZ_Contract),
  Collection(
    info:CollectionInfo(
      address:MORIES_Contract.contractAddressHex,
      sample:"SAMPLE_MORIES",
      name:MORIES_Contract.name,
      webLink: URL(string:"https://cryptomories.iwwon.com/home")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Mories",
        nearestTokensFileName:"CryptoMories_nearestTokens.json",
        propertiesJsonFileName:"CryptoMories_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(load("CryptoMories_rarityRanks.json"))
    ),
    contract:MORIES_Contract),
  Collection(
    info:CollectionInfo(
      address:JUNGLE_FREAKS_Contract.contractAddressHex,
      sample:"SAMPLE_JUNGLE_FREAK",
      name:JUNGLE_FREAKS_Contract.name,
      webLink: URL(string:"https://junglefreaks.io/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Freaks",
        nearestTokensFileName:"JungleFreaks_nearestTokens.json",
        propertiesJsonFileName:"JungleFreaks_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(load("JungleFreaks_rarityRanks.json"))
    ),
    contract:JUNGLE_FREAKS_Contract),
  Collection(
    info:CollectionInfo(
      address:DOODLES_Contract.contractAddressHex,
      sample:"SAMPLE_DOODLE",
      name:DOODLES_Contract.name,
      webLink: URL(string:"https://doodles.app")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Doodles",
        nearestTokensFileName:nil,//"Doodles_nearestTokens.json",
        propertiesJsonFileName:"Doodles_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(load("Doodles_attributeRanks.json"))
    ),
    contract:DOODLES_Contract),
  Collection(
    info:CollectionInfo(
      address:FRWC_Contract.contractAddressHex,
      sample:"SAMPLE_FRWC",
      name:FRWC_Contract.name,
      webLink: URL(string:"https://www.forgottenrunes.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Wizards",
        nearestTokensFileName:nil,//"Doodles_nearestTokens.json",
        propertiesJsonFileName:"FRWC_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(load("FRWC_attributeRanks.json"))
    ),
    contract:FRWC_Contract),
  Collection(
    info:CollectionInfo(
      address:PHUNKS_Contract.contractAddressHex,
      sample:"SAMPLE_PHUNK",
      name:PHUNKS_Contract.name,
      webLink: URL(string:"https://www.cryptophunks.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : SimilarTokensGetter(
        label:"Phunk",
        nearestTokensFileName:"CryptoPunks_nearestTokens.json",
        propertiesJsonFileName:"CryptoPunks_attributeScores.json"
      ),
      rarityRanking : RarityRankingImpl(CryptoPunks_rarityRanks)
    ),
    contract:PHUNKS_Contract),
  Collection(
    info:CollectionInfo(
      address:ZUNKS_Contract.contractAddressHex,
      sample:"SAMPLE_ZUNK",
      name:ZUNKS_Contract.name,
      webLink: URL(string:"https://www.cryptozunks.com")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : nil,
      rarityRanking : nil
    ),
    contract:ZUNKS_Contract),
  Collection(
    info:CollectionInfo(
      address:PUDGY_Contract.contractAddressHex,
      sample:"SAMPLE_PUDGY",
      name:PUDGY_Contract.name,
      webLink: URL(string:"https://www.pudgypenguins.io")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : nil,
      rarityRanking : nil
    ),
    contract:PUDGY_Contract),
  Collection(
    info:CollectionInfo(
      address:ILLUMINATI_Contract.contractAddressHex,
      sample:"SAMPLE_ILLUMINATI",
      name:ILLUMINATI_Contract.name,
      webLink: URL(string:"https://www.illuminatinft.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : nil,
      rarityRanking : nil
    ),
    contract:ILLUMINATI_Contract),
  Collection(
    info:CollectionInfo(
      address:CHUBBI_FRENS_Contract.contractAddressHex,
      sample:"SAMPLE_CHUBBI_FRENS",
      name:CHUBBI_FRENS_Contract.name,
      webLink: URL(string:"https://www.chubbiverse.com/")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : nil,
      rarityRanking : nil
    ),
    contract:CHUBBI_FRENS_Contract),
  Collection(
    info:CollectionInfo(
      address:SSFU_Contract.contractAddressHex,
      sample:"SAMPLE_SSFU",
      name:SSFU_Contract.name,
      webLink: URL(string:"https://www.spikyspacefish.com/home")!,
      themeColor:Color.gunmetal,
      themeLabelColor:Color.white,
      disableRecentTrades:false,
      similarTokens : nil,
      rarityRanking : nil
    ),
    contract:SSFU_Contract),
  Collection(
    info:CollectionInfo(
      address:cryptoKittiesContract.contractAddressHex,
      sample:SAMPLE_KITTIES[0],
      name:"CryptoKitties",
      webLink: URL(string:"https://www.cryptokitties.co")!,
      themeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),
      themeLabelColor:Color.systemBackground,
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

let SampleCollection = CompositeCollection.loaders[0].collection

let COLLECTIONS : [Collection] = CompositeCollection.loaders.map { $0.collection }

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
  case quoteType = "quoteType"
  case offerNotificationMinimum = "offerNotificationMinimum"
}

class NftOwnerTokens : ObservableObject {
  @Published var tokens: [(Collection,NFTWithLazyPrice)] = []
  
  enum LoadingState {
    case notLoaded
    case loading
    case loaded
  }
  @Published var state : LoadingState = .notLoaded
  
  let ownerAddress : EthereumAddress
  private let collections : [Collection]
  
  private var pendingCount = 0
  
  init(ownerAddress:EthereumAddress) {
    self.ownerAddress = ownerAddress
    self.collections = COLLECTIONS
  }
  
  func load() {
    if (state != .notLoaded) { return }
    
    state = .loading
    collections.forEach { collection in
      collection.contract.getOwnerTokens(
        address:ownerAddress,
        
        onDone: {
          DispatchQueue.main.async {
            self.state = .loaded
          }
        }
      ) { token in
        DispatchQueue.main.async {
          self.tokens.append((collection,token))
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
