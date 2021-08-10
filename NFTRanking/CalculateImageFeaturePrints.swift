//
//  CalculateImageFeaturePrints.swift
//  CreateRankingFiles
//
//  Created by Varun Kohli on 7/22/21.
//

import Foundation

import Vision

class CalculateImageFeaturePrints {
  let firstIndex : Int
  let lastIndex : Int
  let collectionName : String  
  var tokenImages : [VNFeaturePrintObservation?]
  
  init(firstIndex:Int,lastIndex:Int,collectionName:String) {
    self.firstIndex = firstIndex
    self.lastIndex = lastIndex
    self.collectionName = collectionName
    self.tokenImages = Array(repeating:nil, count: (lastIndex + 1))
  }
  
  private func featureprintObservationForImage(tokenId:Int) -> VNFeaturePrintObservation? {
    let requestHandler = VNImageRequestHandler(data:loadImageData(collectionName,UInt(tokenId)), options: [:])
    let request = VNGenerateImageFeaturePrintRequest()
    do {
      try requestHandler.perform([request])
      return request.results?.first as? VNFeaturePrintObservation
    } catch {
      print("Vision error: \(error)")
      return nil
    }
  }
  
  private func getTokenImageObservation(_ tokenId:Int) -> VNFeaturePrintObservation? {
    switch(tokenImages[tokenId]) {
    case .none:
      let image = featureprintObservationForImage(tokenId: tokenId)
      tokenImages[tokenId] = image
      return image
    case .some(let image):
      return image
    }
  }
  
  func calculateFeatures() {
    print("Calculating Features")
    for tokenId in firstIndex...lastIndex {
      if (self.tokenImages[tokenId] == nil) {
        self.tokenImages[tokenId] = getTokenImageObservation(tokenId)
      }
      print("Feature Printed \(tokenId)")
    }
    
    let data = try! NSKeyedArchiver.archivedData(
      withRootObject: tokenImages,
      requiringSecureCoding: true
    )
    let filename = getFeaturesFilename(collectionName)
    print("Saving file=\(filename)")
    try! data.write(to: filename)
  }
  
  func loadFeaturesFromFile() {
    let data = try! Data(contentsOf: getFeaturesFilename(collectionName))
    self.tokenImages = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [VNFeaturePrintObservation?]
  }
  
}
