//
//  main.swift
//  CreateAttributeScores
//
//  Created by Varun Kohli on 8/14/21.
//

import Foundation

let collectionName = "Apex Athletes"
let attributesDir = "QmXJQdhhNSCWwUKVTYczV495Mzj8zQN3Q2ZrzGoVFeiXkx"

let isFull = true
let firstIndex = 1
let lastIndex = isFull ? 1800 : 100

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
