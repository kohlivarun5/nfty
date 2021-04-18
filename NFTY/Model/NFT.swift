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

struct CollectionInfo: Hashable, Codable {
  var url1: String
  var url2: String
  var url3: String
  var url4: String
  var name: String
  var totalSupply: Int
  var nfts:[NFT]
}

var SAMPLE_PUNKS = [
  "SamplePunk1",
  "SamplePunk2",
  "SamplePunk3",
  "SamplePunk4",
  "SamplePunk5"
]

var CrypotPunksNfts : [NFT] = load("punks.json")

var CryptoPunksCollection = CollectionInfo(url1:"SamplePunk1",url2:"SamplePunk2",url3:"SamplePunk3",url4:"SamplePunk4",name:String("CRYPTOPUNKS"),totalSupply:10000,nfts:CrypotPunksNfts)

var COLLECTIONS: [CollectionInfo]=[
  CryptoPunksCollection
]
