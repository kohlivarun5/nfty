//
//  CalculateImageDistances.swift
//  NFTY
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation
import Vision

class CalculateImageDistances {
  let firstIndex : Int
  let lastIndex : Int
  let collectionName : String
  let MAX_DISTANCE = Float.infinity
  
  var tokenImages : [VNFeaturePrintObservation?]
  var distances : [[TokenDistance]]
    
  init(firstIndex:Int,lastIndex:Int,collectionName:String,tokenImages : [VNFeaturePrintObservation?]) {
    self.firstIndex = firstIndex
    self.lastIndex = lastIndex
    self.collectionName = collectionName
    self.tokenImages = tokenImages
    self.distances = Array(repeating: [], count: lastIndex + 1)
  }
  
  func calculateDistances() {
    print("Calculating Distances")
    for tokenId in firstIndex...lastIndex {
      distances[tokenId] = Array(repeating:[-1.0,-1.0],count:(lastIndex + 1))
    }
    
    print("Creating images")
    for tokenId in firstIndex...lastIndex {
      print("Starting tokenId=\(tokenId)")
      let image1 = tokenImages[tokenId]
      
      guard let image1Unwrapped = image1 else {
        // print("tokenid=\(tokenId) is empty")
        for tokenId2 in (firstIndex+1)...lastIndex {
          distances[tokenId][tokenId2] = [Float(tokenId2),MAX_DISTANCE]
        }
        continue
      }
      
      for tokenId2 in firstIndex...lastIndex {
        
        guard let image2 = tokenImages[tokenId2] else {
          // print("tokenid=\(tokenId2) is empty")
          distances[tokenId][tokenId2] = [Float(tokenId2),MAX_DISTANCE]
          continue
        }
        
        var distance : Float = -1.0
        try? image1Unwrapped.computeDistance(&distance, to: image2)
        distances[tokenId][tokenId2] = [Float(tokenId2),Float(distance)]
        // print("Done tokenId2=\(tokenId2)")
      }
      distances[tokenId].sort(by:{$0[1] < $1[1]})
      print("Done tokenId=\(tokenId)")
    }
    
    saveJSON(getDistancesFilename(collectionName),distances)
    print("Done Calculating Distances")
    
  }

  func loadDistancesFromFile() {
    print("Loading DistancesFromFile")
    distances = loadJSON(getDistancesFilename(collectionName))
    print("Done DistancesFromFile")
  }
  
}
