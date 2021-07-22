//
//  main.swift
//  CreateRankingFiles
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation

// PARAMETERS

let collectionName = "CryptoHodlers"

let isFull = false
let firstIndex = 0
let lastIndex = isFull ? 9999 : 10

// STAGES
let doCalculateDistances = true
let doNearestNeghbors = true
let doCalculateRarityRank = true


// PIPELINE

let calculator = CalculateImageDistances(firstIndex: 0,lastIndex: isFull ? 9999 : 10,collectionName:collectionName)
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
