//
//  IpfsDownloader.swift
//  DownloadCollection
//
//  Created by Varun Kohli on 8/14/21.
//

import Foundation


class IpfsCollectionContract : ContractInterface {
  
  class IpfsImageEthContract : EthereumContract {
    
    struct TokenUriData : Codable {
      let image : String
    }
    
    struct TokenData : Codable {
      let data : TokenUriData
      let image : Data?
    }
    
    static func imageOfData(_ data:Data?) -> Media.IpfsImage? {
      return data
        .flatMap { UIImage(data:$0) }
        .flatMap { $0.jpegData(compressionQuality: 0.1) }
        .flatMap { UIImage(data:$0) }
        .map { Media.IpfsImage(image:$0) }
    }
    
    func image(_ tokenId:BigUInt) -> Promise<TokenUriData?> {
      return ethContract.tokenURI(tokenId:tokenId)
        .then(on: DispatchQueue.global(qos:.userInteractive)) { (uri:String) -> Promise<TokenUriData> in
          
          return Promise { seal in
            
            var request = URLRequest(
              url:URL(string: uri.replacingOccurrences(
                        of: "ipfs://",
                        with: "https://ipfs.infura.io:5001/api/v0/cat?arg="))!)
            request.httpMethod = "GET"
            
            print("calling \(request.url!)")
            URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
              // print(data,response,error)
              do {
                switch(data) {
                case .some(let data):
                  if (data.isEmpty) {
                    // print(data,response,error)
                    seal.reject(NSError(domain:"", code:404, userInfo:nil))
                  } else {
                    seal.fulfill(try JSONDecoder().decode(TokenUriData.self, from: data))
                  }
                case .none:
                  // print(data,response,error)
                  seal.reject(error ?? NSError(domain:"", code:404, userInfo:nil))
                }
              } catch {
                // print(data,response,error)
                seal.reject(error)
              }
            }).resume()
          }
          
        }.then(on: DispatchQueue.global(qos:.userInitiated)) { (uriData:TokenUriData) -> Promise<Data?> in
          
          return Promise { seal in
            
            var request = URLRequest(
              url:URL(string:uriData.image.replacingOccurrences(of: "ipfs://", with: "https://ipfs.infura.io:5001/api/v0/cat?arg="))!)
            request.httpMethod = "GET"
            
            print("calling \(request.url!)")
            URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
              // print(data,response,error)
              seal.fulfill(data)
            }).resume()
          }
        }
    }
  }
