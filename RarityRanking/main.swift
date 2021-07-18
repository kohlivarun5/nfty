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

let collectionName = "FameLadySquad"
//let totalSupply = 10000

typealias TokenDistance = [Float]

func load<T:Decodable>(_ name:String) -> T {
  
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

struct TokenSumOfClosest {
  var tokenId: Int
  var sum: Float
}

let closestForRanking = 10

let nearestTokens : [ [TokenDistance] ] = load("nearestTokens")
print("Loaded distances")
let closestSums = nearestTokens.enumerated().map { (index,distances) in
  return TokenSumOfClosest(tokenId:index,sum:distances.prefix(10).reduce(0) { $0 + $1[1] })
}.sorted(by: { $0.sum > $1.sum } )

var ranks : [Int] =  Array(repeating: 0, count:nearestTokens.count)
closestSums.enumerated().map { (index,info) in
  ranks[info.tokenId] = index + 1
}

save("rarityRanks",ranks)

print("Done")
