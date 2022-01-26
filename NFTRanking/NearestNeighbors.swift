//
//  NearestNeighbors.swift
//  NFTY
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation

class NearestNeighbors {
  let closestNeighborsNum = 100
  var nearestTokens : [ [Float] ] = [[]]
  let collectionName : String
  
  init(collectionName:String) { self.collectionName = collectionName }
  
  func saveNearestNeighbors(distances : [[TokenDistance]]) {
    
    // iterate for each token and collect it's closest neighbors
    // Also, sum those neighbors and save as token score
    print("Calculating NearestNeighbors")
    let nearestNeighbors : [[TokenDistance]] = distances.map { tokenDistances in
      Array(tokenDistances
        .filter { $0[1] > 0 }
        .prefix(closestNeighborsNum))
        
    }
    
    self.nearestTokens = nearestNeighbors.map { tokenDistances in
      tokenDistances.map { $0[0] }
    }
    
    saveJSON(getNeighborsFilename(collectionName),nearestTokens)
  }
  
  func loadFromFile() { nearestTokens = loadJSON(getNeighborsFilename(collectionName)) }
  
}
