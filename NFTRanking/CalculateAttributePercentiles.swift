//
//  CalculateAttributePercentiles.swift
//  CreateRankingFiles
//
//  Created by Varun Kohli on 8/14/21.
//

import Foundation

class CalculateAttributePercentiles {
  let firstIndex : Int
  let lastIndex : Int
  let collectionName : String
  
  // Each attribute contains a dict of the value and count of items wioth that value
  var attributes : [ String : [String : UInt] ] = [:]
  
  init(firstIndex:Int,lastIndex:Int,collectionName:String) {
    self.firstIndex = firstIndex
    self.lastIndex = lastIndex
    self.collectionName = collectionName
  }
  
  func calculatePercentiles() {
    print("Calculating Percentiles")
    
    for tokenId in firstIndex...lastIndex {
      print("Starting tokenId=\(tokenId)")
      
      let attributes : [Erc721TokenAttribute] = loadJSON(getAttributesFileName(collectionName,UInt(tokenId)))
      
      attributes.forEach { attr in
        var traitDict = self.attributes[attr.trait_type] ?? [:]
        traitDict[attr.value] = (traitDict[attr.value] ?? 0) + 1
        self.attributes[attr.trait_type] = traitDict
      }
      
      print("Done tokenId=\(tokenId)")
    }
    
    saveJSON(getAttributePercentilesFilename(collectionName),self.attributes)
    print("Done Calculating Percentiles")
    
  }
  
  func loadPercentilesFromFile() { attributes = loadJSON(getAttributePercentilesFilename(collectionName)) }
  
}
