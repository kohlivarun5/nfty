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
}

var SAMPLE_PUNKS : [String] = [
  "SamplePunk1",
  "SamplePunk2",
  "SamplePunk3",
  "SamplePunk4"
]

var CrypotPunksNfts : [NFT] = load("punks.json")

var CryptoPunksCollection = CollectionInfo(url1:SAMPLE_PUNKS[0],url2:SAMPLE_PUNKS[1],url3:SAMPLE_PUNKS[2],url4:SAMPLE_PUNKS[3],name:"CRYPTOPUNKS",totalSupply:10000,nfts:CrypotPunksNfts,themeColor:Color.yellow)

var COLLECTIONS: [CollectionInfo]=[
  CryptoPunksCollection
]
