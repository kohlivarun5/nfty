//
//  main.swift
//  CreateRankingFiles
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation

// PARAMETERS

let collectionName = "DeadFellaz"

let isFull = true
let firstIndex = 1
let lastIndex = isFull ? 10000 : 100

// STAGES
let doCalculateFeatures = true
let doCalculateDistances = true
let doNearestNeghbors = true
let doCalculateRarityRank = true


// PIPELINE

let features = CalculateImageFeaturePrints(firstIndex: firstIndex,lastIndex: lastIndex,collectionName:collectionName)
// features.loadFeaturesFromFile()
if (doCalculateFeatures) {
  features.calculateFeatures()
}

let calculator = CalculateImageDistances(firstIndex: firstIndex,lastIndex: lastIndex,collectionName:collectionName,tokenImages: features.tokenImages)
if (doCalculateDistances) {
  calculator.calculateDistances()
} else {
  calculator.loadDistancesFromFile()
}

let neighbors = NearestNeighbors(collectionName:collectionName)
if (doNearestNeghbors) {
  neighbors.saveNearestNeighbors(distances:calculator.distances)
} else {
  neighbors.loadFromFile()
}

let rarityCalc = CalculateRarityRank(collectionName: collectionName)
if (doCalculateRarityRank) {
  rarityCalc.saveRanking(distances:calculator.distances)
}
