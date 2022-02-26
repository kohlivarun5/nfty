//
//  main.swift
//  CreateAttributeScores
//
//  Created by Varun Kohli on 8/14/21.
//

import Foundation

let collectionName = "kaizofighters.tenk.near"
let attributesDir = "bafybeie3tapnsmwdzhrq6vzb6vpo623kxgominzaiyxh7igdrskk2drdj4"

let isFull = true
let firstIndex = 1
let lastIndex = isFull ? 4693 : 100

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
