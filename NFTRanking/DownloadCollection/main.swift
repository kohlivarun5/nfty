//
//  main.swift
//  DownloadCollection
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation
import PromiseKit
import BigInt

let contract = IpfsCollectionContract(
  name: "CryptoHodlers",
  address: "0xe12a2A0Fb3fB5089A498386A734DF7060c1693b8")
let collectionName = contract.name
let firstIndex = 0
let lastIndex = 9999

print("Started downloading collection:\(collectionName)")

func saveToken(_ tokenId : Int) -> Promise<Void> {
  return contract.ethContract.image(BigUInt(tokenId))
    .map { image -> Void in
      print("Downloaded \(tokenId)")
      let filename = getImageFileName(collectionName,UInt(tokenId))
      try? image?.data.write(to: filename)
    }
}

let parallelCount = 10

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
      let p =
        fileManager.fileExists(atPath: getImageFileName(collectionName,UInt(tokenId)).path)
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

try? hang(when(fulfilled:prev))
print("Done")
