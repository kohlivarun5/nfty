//
//  main.swift
//  CreateAttributeScores
//
//  Created by Varun Kohli on 8/14/21.
//

import Foundation

let collectionName = "asac.near"
let attributesDir = "bafybeicj5zfhe3ytmfleeiindnqlj7ydkpoyitxm7idxdw2kucchojf7v4"

let isFull = true
let firstIndex = 0
let lastIndex = isFull ? 3332 : 100

// STAGES
let doCalculatePercentiles = true
let doCalculateAttrScores = true



// Percentiles
let percentiles = CalculateAttributePercentiles(
  firstIndex: firstIndex,
  lastIndex: lastIndex,
  collectionName: collectionName,
  attributesDir: attributesDir)

if (doCalculatePercentiles) {
  percentiles.calculatePercentiles()
} else {
  percentiles.loadPercentilesFromFile()
}

let attrScores = CalculatePercentileScores(
  firstIndex: firstIndex,
  lastIndex: lastIndex,
  collectionName: collectionName,
  attributesDir: attributesDir,
  attributes: percentiles.attributes)
if (doCalculateAttrScores) {
  attrScores.calculateScores()
}
