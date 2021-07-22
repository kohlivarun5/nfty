//
//  CalculateImageDistances.swift
//  NFTY
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation
import Vision

typealias TokenDistance = [Float]

class CalculateImageDistances {
  let firstIndex : Int
  let lastIndex : Int
  let collectionName : String
  
  var tokenImages : [VNFeaturePrintObservation?]
  var distances : [[TokenDistance]]
    
  init(firstIndex:Int,lastIndex:Int,collectionName:String) {
    self.firstIndex = firstIndex
    self.lastIndex = lastIndex
    self.collectionName = collectionName
    self.tokenImages = Array(repeating:nil, count: (lastIndex - firstIndex) + 1)
    self.distances = Array(repeating: [], count: (lastIndex - firstIndex) + 1)
  }
  
  private func featureprintObservationForImage(tokenId:Int) -> VNFeaturePrintObservation? {
    let requestHandler = VNImageRequestHandler(data:loadImageData(collectionName,UInt(tokenId)), options: [:])
    let request = VNGenerateImageFeaturePrintRequest()
    do {
      try requestHandler.perform([request])
      return request.results?.first as? VNFeaturePrintObservation
    } catch {
      print("Vision error: \(error)")
      return nil
    }
  }
  
  private func getTokenImageObservation(_ tokenId:Int) -> VNFeaturePrintObservation? {
    switch(tokenImages[tokenId]) {
    case .none:
      let image = featureprintObservationForImage(tokenId: tokenId)
      tokenImages[tokenId] = image
      return image
    case .some(let image):
      return image
    }
  }
  
  func calculateDistances() {
    print("Calculating Distances")
    for tokenId in firstIndex...lastIndex {
      distances[tokenId] = Array(repeating:[-1.0,-1.0],count:(lastIndex - firstIndex + 1))
    }
    
    print("Creating images")
    for tokenId in firstIndex...lastIndex {
      print("Starting tokenId=\(tokenId)")
      let image1 = getTokenImageObservation(tokenId)
      for tokenId2 in (firstIndex+1)...lastIndex {
        let image2 = getTokenImageObservation(tokenId2)
        var distance : Float = -1.0
        try! image1!.computeDistance(&distance, to: image2!)
        distances[tokenId][tokenId2] = [Float(tokenId2),Float(distance)]
        print("Done tokenId2=\(tokenId2)")
      }
      distances[tokenId].sort(by:{$0[1] < $1[1]})
      print("Done tokenId=\(tokenId)")
    }
    
    saveJSON(getDistancesFilename(collectionName),distances)
    print("Done Calculating Distances")
    
  }

  func loadDistancesFromFile() { distances = loadJSON(getDistancesFilename(collectionName)) }
  
}
