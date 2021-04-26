//
//  main.swift
//  RankImages
//
//  Created by Varun Kohli on 4/26/21.
//

import Foundation
import Vision

let totalSupply = 10000
let collectionName = "CryptoPunks"

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}

func loadImageData(tokenId:Int) -> Data {
  let filename = getDocumentsDirectory()
    .appendingPathComponent("../")
    .appendingPathComponent("Github")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("DownloadCryptoPunks")
    .appendingPathComponent("Images")
    .appendingPathComponent(collectionName)
    .appendingPathComponent("png")
    .appendingPathComponent("punk\(String(format: "%04d", Int(tokenId))).png")
  return try! Data(contentsOf: filename)
}

func featureprintObservationForImage(tokenId:Int) -> VNFeaturePrintObservation? {
  let requestHandler = VNImageRequestHandler(data:loadImageData(tokenId:tokenId), options: [:])
  let request = VNGenerateImageFeaturePrintRequest()
  do {
    try requestHandler.perform([request])
    return request.results?.first as? VNFeaturePrintObservation
  } catch {
    print("Vision error: \(error)")
    return nil
  }
}

func save<T: Encodable>(_ obj : T) -> Void? {
  
  let encoder = JSONEncoder()
  encoder.outputFormatting = .prettyPrinted
  let data = try? encoder.encode(obj)

  let filename = getDocumentsDirectory()
    .appendingPathComponent("../")
    .appendingPathComponent("Github")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("Resources")
    .appendingPathComponent("\(collectionName)Distances.json")
  print("Saving file=\(filename)")
  return data.flatMap { try! $0.write(to: filename) }
}

struct TokenDistance: Codable {
  var tokenId: Int
  var distance: Float
}

print("Creating Data")
var distances : [[TokenDistance]] = Array(repeating: [], count: totalSupply)
for tokenId in 0...(totalSupply - 1) {
  distances[tokenId] = Array(repeating:TokenDistance(tokenId:-1,distance:-1),count:totalSupply)
}

print("Creating images")
var tokenImages : [VNFeaturePrintObservation?] = Array(repeating:nil, count: totalSupply)

func getTokenImageObservation(_ tokenId:Int) -> VNFeaturePrintObservation? {
  switch(tokenImages[tokenId]) {
  case .none:
    let image = featureprintObservationForImage(tokenId: tokenId)
    tokenImages[tokenId] = image
    return image
  case .some(let image):
    return image
  }
}

for tokenId in 0...(totalSupply - 1) {
  print("Starting tokenId=\(tokenId)")
  let image1 = getTokenImageObservation(tokenId)
  for tokenId2 in 0...(totalSupply - 1) {
    let image2 = getTokenImageObservation(tokenId2)
    try image1!.computeDistance(&distances[tokenId][tokenId2].distance, to: image2!)
    distances[tokenId][tokenId2].tokenId = tokenId2
    print("Done tokenId2=\(tokenId2)")
  }
  distances[tokenId].sort(by:{$0.distance < $1.distance})
  print("Done tokenId=\(tokenId)")
}

save(distances)
print("Done")
