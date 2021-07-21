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

let startIndexKey = "DownloadCollection.\(collectionName).startTokenId"

let downloadStartIndex = UserDefaults.standard.integer(forKey:startIndexKey)

let parallelCount = 10

var tokenId = downloadStartIndex
var prev : Promise<Int> = Promise.value(tokenId)

while tokenId < (lastIndex + 1) {
  
  let next = prev.then { tokenId -> Promise<Int> in
    print(tokenId)
    var promises : [Promise<Void>] = []
    var count = 0
    while (tokenId + count) < (lastIndex + 1) && count < parallelCount {
      print(tokenId,count)
      promises.append(saveToken(tokenId + count))
      count+=1
    }
    return when(fulfilled:promises).map { () -> Int in
      UserDefaults.standard.set(tokenId, forKey:startIndexKey)
      return tokenId + count
    }
  }
  
  tokenId+=parallelCount
  prev = next
  
}

try? hang(prev)
print("Done")
