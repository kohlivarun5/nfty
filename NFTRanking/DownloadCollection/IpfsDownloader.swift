//
//  IpfsDownloader.swift
//  DownloadCollection
//
//  Created by Varun Kohli on 8/14/21.
//

import Foundation
import BigInt
import PromiseKit


import Cocoa

extension NSImage {
  
  private func compressedJPEG(with factor: Double) -> Data? {
    guard let tiff = tiffRepresentation else { return nil }
    guard let imageRep = NSBitmapImageRep(data: tiff) else { return nil }
    
    let options: [NSBitmapImageRep.PropertyKey: Any] = [
      .compressionFactor: factor
    ]
    
    return imageRep.representation(using: .jpeg, properties: options)
  }
  
  var compressedJPEGRepresentation: Data? {
    return compressedJPEG(with: 0.01)
  }
  
}
struct IpfsDownloader {
  let name : String
  let baseUri : String
   
  let ipfsHost : String? = "http://ipfs.io/ipfs/" //"http://127.0.0.1:8080/ipfs/"
  
  func tokenData(_ tokenId:BigUInt) -> Promise<Erc721TokenData> {
    return Promise { seal in
      
      var uri = "\(baseUri)/\(tokenId)"
      
      uri =
        ipfsHost.map {
          uri
            .replacingOccurrences(
              of: "ipfs://",
              with: $0)
            .replacingOccurrences(
              of: "https://ipfs.io/ipfs/",
              with: $0)
            .replacingOccurrences(
              of: "https://gateway.pinata.cloud/ipfs/",
              with: $0)
        } ?? uri
      
      var request = URLRequest(url:URL(string:uri)!)
      request.httpMethod = "GET"
      
      print("calling \(request.url!)")
      URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
        // print(data,response,error)
        do {
          switch(data) {
          case .some(let data):
            if (data.isEmpty) {
              print(data,response,error)
              seal.reject(NSError(domain:"", code:404, userInfo:nil))
            } else {
              seal.fulfill(try JSONDecoder().decode(Erc721TokenUriData.self, from: data))
            }
          case .none:
            print(data,response,error)
            seal.reject(error ?? NSError(domain:"", code:404, userInfo:nil))
          }
        } catch {
          print(data,response,error)
          seal.reject(error)
        }
      }).resume()
    }
    .then(on: DispatchQueue.global(qos:.userInitiated)) { (uriData:Erc721TokenUriData) -> Promise<Erc721TokenData> in
      
      return Promise { seal in
        
        var uri = uriData.image
        uri =
          ipfsHost.map {
            uri
              .replacingOccurrences(
                of: "ipfs://",
                with: $0)
              .replacingOccurrences(
                of: "https://ipfs.io/ipfs/",
                with: $0)
              .replacingOccurrences(
                of: "https://gateway.pinata.cloud/ipfs/",
                with: $0)
          } ?? uri
        
        var request = URLRequest(url:URL(string:uri)!)
        request.httpMethod = "GET"
        
        print("calling \(request.url!)")
        URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
          // print(data,response,error)
          switch(data) {
          case .some(let data):
            let compressed = NSImage(data:data)!.compressedJPEGRepresentation!
            seal.fulfill(Erc721TokenData(image:compressed,attributes:uriData.attributes))
          case .none:
            print(data,response,error)
            seal.reject(error ?? NSError(domain:"", code:404, userInfo:nil))
          }
        }).resume()
      }
    }
  }
}
