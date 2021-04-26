//
//  main.swift
//  ParseTokenDistances
//
//  Created by Varun Kohli on 4/26/21.
//

import Foundation

print("Hello, World!")

let isFull = true

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}

let collectionName = "CryptoPunks"
//let totalSupply = 10000

struct TokenDistance: Codable {
  var tokenId: Int
  var distance: Float
}


func load<T:Decodable>() -> T {
  
  let filename = getDocumentsDirectory()
    .appendingPathComponent("../")
    .appendingPathComponent("Github")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("Resources")
    .appendingPathComponent("\(collectionName)Distances\(isFull ? "" : "_small").json")
  
  let data = try! Data(contentsOf: filename)
  let decoder = JSONDecoder()
  return try! decoder.decode(T.self, from: data)
}

func save<T: Encodable>(_ name:String, _ obj : T) -> Void? {
  
  let encoder = JSONEncoder()
  let data = try? encoder.encode(obj)
  
  let filename = getDocumentsDirectory()
    .appendingPathComponent("../")
    .appendingPathComponent("Github")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("Resources")
    .appendingPathComponent("\(collectionName)_\(name)\(isFull ? "" : "_small").json")
  print("Saving file=\(filename)")
  return data.flatMap { try! $0.write(to: filename) }
}

print("Loading file")
let distances : [[TokenDistance]] = load()
print("File loaded")

var closestNeighborsNum = 100
// iterate for each token and collect it's closest neighbors
// Also, sum those neighbors and save as token score

let nearestNeighbors = distances.map { tokenDistances in
  tokenDistances
    .prefix(closestNeighborsNum)
    .filter { $0.distance != 0 }
}

let nearestTokens = nearestNeighbors.map { tokenDistances in
  tokenDistances
    .map { $0.tokenId }
}

save("nearestTokens",nearestTokens)

print("Done")
