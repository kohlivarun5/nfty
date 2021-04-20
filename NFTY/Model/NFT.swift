//
//  NFT.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import Foundation
import SwiftUI

struct NFT: Hashable, Codable {
    var address: String
   var tokenId: String
   var name: String
   var url: URL
   var eth: Double
}



struct CollectionInfo {
  var url1: String
  var url2: String
  var url3: String
  var url4: String
  var name: String
  var totalSupply: Int
  var nfts:[NFT]
  var themeColor:Color
  var blur:CGFloat
  var samplePadding:CGFloat
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

var CrypotPunksNfts : [NFT] = load("punks.json")

var CryptoKittiesNfts : [NFT] = load("kitties.json")

var CryptoPunksCollection = CollectionInfo(url1:SAMPLE_PUNKS[0],url2:SAMPLE_PUNKS[1],url3:SAMPLE_PUNKS[2],url4:SAMPLE_PUNKS[3],name:"CRYPTOPUNKS",totalSupply:10000,nfts:CrypotPunksNfts,themeColor:Color.yellow,blur:0,samplePadding:10)
var CryptoKittiesCollection = CollectionInfo(url1:SAMPLE_KITTIES[0],url2:SAMPLE_KITTIES[1],url3:SAMPLE_KITTIES[2],url4:SAMPLE_KITTIES[3],name:"CryptoKitties",totalSupply:1997622,nfts:CryptoKittiesNfts,themeColor: /* 78e08f */ Color(red: 120/255, green: 224/255, blue: 143/255),blur:0,samplePadding:0)

var COLLECTIONS: [CollectionInfo]=[
  CryptoPunksCollection,
  CryptoKittiesCollection
]
