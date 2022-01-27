//
//  CalculatePercentileScores.swift
//  CreateRankingFiles
//
//  Created by Varun Kohli on 8/14/21.
//

import Foundation

class CalculatePercentileScores {
  let firstIndex : Int
  let lastIndex : Int
  let collectionName : String
  let attributesDir : String
  
  // Each attribute contains a dict of the value and count of items wioth that value
  let attributes : [ String : [String : UInt] ]
  
  var tokenScores : [UInt]
  
  struct TokenAttributePercentile : Codable {
    let name : String
    let value : String
    let percentile : Double
  }
  
  var tokenAttributes : [ [TokenAttributePercentile] ]
  
  init(firstIndex:Int,lastIndex:Int,collectionName:String,attributesDir:String,attributes:[ String : [String : UInt] ]) {
    self.firstIndex = firstIndex
    self.lastIndex = lastIndex
    self.collectionName = collectionName
    self.attributesDir = attributesDir
    self.attributes = attributes
    self.tokenScores = Array(repeating: 0, count: lastIndex + 1)
    self.tokenAttributes = Array(repeating: [], count: lastIndex + 1)
  }
  
  func calculateScores() {
    print("Calculating Scores")
    
    let totalCount = lastIndex - firstIndex + 1
    
    for tokenId in firstIndex...lastIndex {
      print("Starting tokenId=\(tokenId)")
      
      let data : Erc721TokenUriData = loadJSON(getAttributesFileName(
        collectionName:collectionName,
        attributesDir: attributesDir,
        UInt(tokenId)))
      let attributes = data.attributes
      
      var score = 0
      attributes.forEach { attr in
        let count = self.attributes[attr.trait_type]?[attr.value] ?? 0
        score = score + (totalCount - Int(count))
        
        self.tokenAttributes[tokenId].append(
          TokenAttributePercentile(
            name:attr.trait_type,
            value:attr.value,
            percentile: Double(count)/Double(totalCount))
        )
      }
      self.tokenScores[tokenId] = UInt(score)
      print("Done tokenId=\(tokenId)")
    }
    
    saveJSON(getAttributeScoresFilename(collectionName),self.tokenAttributes)
    print("Done Calculating Attribute Scores")
    
    let tokensSortedByScore = self.tokenScores.enumerated()
      .sorted(by: { $0.element > $1.element } )
    
    // print(tokensSortedByScore)
    var ranks : [Int] =  Array(repeating: 0, count: lastIndex + 1)
    _ = tokensSortedByScore.enumerated().map { (index,info) in
      ranks[Int(info.offset)] = index + 1
    }
    // print(tokensSortedByScore)
    saveJSON(getAttributeRankFilename(collectionName),ranks)
    print("Done Calculating Attribute Ranks")
    
  }
  
}
