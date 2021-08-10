//
//  main.swift
//  DownloadCollection
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation
import PromiseKit
import BigInt

//let contract = UrlCollectionContract(name: "CryptoCannabisClub", address: "0x80a4B80C653112B789517eb28aC111519b608b19", baseUri: "https://api.cryptocannabisclub.com/image/")
let collectionName = "CryptoCannabisClub"
let firstIndex = 1
let lastIndex = 10000

let minFileSize = 1000
let parallelCount = 5


func image(_ tokenId:BigUInt) -> Promise<Data?> {
  return Promise { seal in
    var request = URLRequest(url:URL(string:"https://api.cryptocannabisclub.com/image/\(tokenId)")!)
    request.httpMethod = "GET"
    URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
      // print(data,response,error)
      seal.fulfill(data)
    }).resume()
  }
}

print("Started downloading collection:\(collectionName)")

func saveToken(_ tokenId : Int) -> Promise<Void> {
  return image(BigUInt(tokenId))
    .map { image -> Void in
      print("Downloaded \(tokenId)")
      let filename = getImageFileName(collectionName,UInt(tokenId))
      try? image?.write(to: filename)
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
