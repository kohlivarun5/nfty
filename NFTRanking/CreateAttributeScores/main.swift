//
//  main.swift
//  CreateAttributeScores
//
//  Created by Varun Kohli on 8/14/21.
//

import Foundation

let collectionName = "Doodles"

let isFull = true
let firstIndex = 0
let lastIndex = isFull ? 9999 : 100

// STAGES
let doCalculatePercentiles = true
let doCalculateAttrScores = true



// Percentiles
let percentiles = CalculateAttributePercentiles(firstIndex: firstIndex, lastIndex: lastIndex, collectionName: collectionName)
if (doCalculatePercentiles) {
  percentiles.calculatePercentiles()
} else {
  percentiles.loadPercentilesFromFile()
}

let attrScores = CalculatePercentileScores(
  firstIndex: firstIndex,
  lastIndex: lastIndex,
  collectionName: collectionName,
  attributes: percentiles.attributes)
if (doCalculateAttrScores) {
  attrScores.calculateScores()
}
