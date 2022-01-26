//
//  CalculateRarityRank.swift
//  NFTY
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation

struct CalculateRarityRank {
  struct TokenSumOfClosest {
    var tokenId: Int
    var sum: Float
  }
  
  let closestForRanking = 10
  let collectionName : String
  func saveRanking(distances : [[TokenDistance]]) {
    
    let closestSums = distances.enumerated().map { (index,distances) in
      return TokenSumOfClosest(
        tokenId:index,
        sum:distances
          .filter { $0[1] > 0 }
          .prefix(closestForRanking)
          .reduce(0) { $0 + $1[1] }
      )
    }.sorted(by: { $0.sum > $1.sum } )
    
    var ranks : [Int] =  Array(repeating: 0, count:distances.count)
    closestSums.enumerated().map { (index,info) in
      ranks[info.tokenId] = index + 1
    }
    
    saveJSON(getRarityRankFilename(collectionName),ranks)
  }
}
