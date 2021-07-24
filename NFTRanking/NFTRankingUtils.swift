//
//  NFTRankingUtils.swift
//  NFTY
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation

typealias TokenDistance = [Float]

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}

func getResourcesDirectory() -> URL {
  return getDocumentsDirectory()
    .appendingPathComponent("../")
    .appendingPathComponent("Github")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("Resources")
}

func getDistancesFilename(_ collectionName:String) -> URL {
  return getResourcesDirectory()
    .appendingPathComponent("\(collectionName)Distances.json")
}

func getFeaturesFilename(_ collectionName:String) -> URL {
  return getResourcesDirectory()
    .appendingPathComponent("\(collectionName)Features.json")
}


func getNeighborsFilename(_ collectionName:String) -> URL {
  return getResourcesDirectory()
    .appendingPathComponent("\(collectionName)_nearestTokens.json")
}

func getRarityRankFilename(_ collectionName:String) -> URL {
  return getResourcesDirectory()
    .appendingPathComponent("\(collectionName)_rarityRanks.json")
}

func getImageFileName(_ collectionName:String,_ tokenId:UInt) -> URL {
  return
    getDocumentsDirectory()
    .appendingPathComponent("../")
    .appendingPathComponent("Github")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("data")
    .appendingPathComponent("Images")
    .appendingPathComponent(collectionName)
    .appendingPathComponent("png")
    .appendingPathComponent("\(tokenId).png")
  
}

func loadImageData(_ collectionName:String,_ tokenId:UInt) -> Data {
  let filename = getImageFileName(collectionName,tokenId)
  return try! Data(contentsOf: filename)
}

func saveJSON<T: Encodable>(_ filename:URL,_ obj : T) -> Void? {
  let encoder = JSONEncoder()
  let data = try? encoder.encode(obj)
  print("Saving file=\(filename)")
  return data.flatMap { try! $0.write(to: filename) }
}

func loadJSON<T:Decodable>(_ filename:URL) -> T {
  let data = try! Data(contentsOf: filename)
  let decoder = JSONDecoder()
  return try! decoder.decode(T.self, from: data)
}
