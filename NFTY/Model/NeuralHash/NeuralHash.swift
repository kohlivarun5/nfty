//
//  NeuralHash.swift
//  NFTY
//
//  Created by Varun Kohli on 7/7/22.
//

import Foundation
import Vision

struct NeuralHash {
  
  static func generate(image: Data, onDone : @escaping (String?) -> Void) {
    return onDone(nil)
    /*
    let requestHandler = VNImageRequestHandler(data: image)// VNImageRequestHandler(url: imagePathURL, options: [:])
    
    let neuralHashRequest = VN6kBnCOr2mZlSV6yV1dLwB { req, err in
      guard let result = req.results?.first else { return onDone(nil) }
      guard let observation = result as? VN3XKGTKNBvy6h4RFtpxLyW else { return onDone(nil) }
      let imageHash = observation.imageSignatureHash()
      do {
        guard let imageHData = try imageHash?.encodeHashDescriptorWithBase64Encoding() else { return onDone(nil) }
        return onDone(imageHData.map { String(format: "%02hhx", $0) }.joined())
      } catch {
        print(error)
      }
      onDone(nil)
    }
    neuralHashRequest.imageSignatureprintType = 3
    neuralHashRequest.imageSignatureHashType = 1
    
    do {
      try requestHandler.perform([neuralHashRequest])
    } catch {
      print("Error: \(error)")
      return onDone(nil)
    }
     */
  }
}
