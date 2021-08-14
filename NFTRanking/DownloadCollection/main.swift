//
//  main.swift
//  DownloadCollection
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation
import PromiseKit
import BigInt

// var web3 = Web3(rpcURL: "https://mainnet.infura.io/v3/c2b9ecfefe934b1ba89dc49532f44bf5")

let downloader = IpfsDownloader(
  name: "CoolCats",
  baseUri:"https://api.coolcatsnft.com/cat/")

let firstIndex = 0
let lastIndex = 9932


/*
 let downloader = IpfsDownloader(
 name: "DeadFellaz",
 baseUri:"https://api.deadfellaz.io/traits/")
 let firstIndex = 1
 let lastIndex = 10000

 */

let collectionName = downloader.name

let minFileSize = 1000
let parallelCount = 5


func image(_ tokenId:BigUInt) -> Promise<Data?> {
  return Promise { seal in
    var request = URLRequest(url:URL(string:"https://tbh-data.s3.amazonaws.com/final/images/\(tokenId)")!)
    request.httpMethod = "GET"
    URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
      // print(data,response,error)
      seal.fulfill(data)
    }).resume()
  }
}

print("Started downloading collection:\(collectionName)")

func saveToken(_ tokenId : Int) -> Promise<Void> {
  return downloader.tokenData(BigUInt(tokenId))
    .map { data -> Void in
      print("Downloaded \(tokenId)")
      let filename = getImageFileName(collectionName,UInt(tokenId))
      try? data.image.write(to: filename)
    }
}

var tokenId = firstIndex
var prev : [Promise<Int>] = Array(repeating:Promise.value(tokenId), count: parallelCount)

for index in 0...(parallelCount-1) {
  prev[index] = Promise.value(index)
}

let fileManager = FileManager.default

while tokenId < (lastIndex + 1) {
  
  for index in 0...(parallelCount-1) {
    let next = prev[index].then { tokenId -> Promise<Int> in
      // print(tokenId,count)
      let fileName = getImageFileName(collectionName,UInt(tokenId)).path
      let p =
        fileManager.fileExists(atPath:fileName)
        && (minFileSize < (try! fileManager.attributesOfItem(atPath:fileName))[FileAttributeKey.size] as! UInt64)
        ? Promise.value(tokenId+parallelCount)
        : saveToken(tokenId).map { tokenId + parallelCount }
      return p.map { index in
        print("Done \(index)")
        return index
      }
    }
    prev[index] = next
  }
  tokenId+=parallelCount
}

try hang(when(fulfilled:prev))
print("Done downloading. Verifing now")

var indexMissing = false

for index in firstIndex...lastIndex {
  let path = getImageFileName(collectionName,UInt(index)).path
  indexMissing = indexMissing || !fileManager.fileExists(atPath:path)
  
  let attr = try fileManager.attributesOfItem(atPath: path)
  if (minFileSize > attr[FileAttributeKey.size] as! UInt64) {
    print("Token=\(index) is empty")
    // try fileManager.removeItem(atPath: path)
  }
  
}
print("All downloaded=\(!indexMissing)")
