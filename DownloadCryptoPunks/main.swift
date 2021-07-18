//
//  main.swift
//  RankTokenImages
//
//  Created by Varun Kohli on 4/25/21.
//

import Foundation
import PromiseKit
import BigInt

print("Hello, World!")

let contract = fameLadyContract

var collectionName = contract.name
let totalSize = 8888


func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}

func downloadImageUrl(url:URL) -> Data? {
  return try? Data(contentsOf: url)
}

private func makeImageUrl(_ tokenId:UInt) -> URL {
  // till 4443 inclusive, it is QmRRRcbfE3fTqBLTmmYMxENaNmAffv7ihJnwFkAimBP4Ac
  // after it is QmTwNwAerqdP3LXcZnCCPyqQzTyB26R5xbsqEy5Vh3h6Dw
  
  return URL(string:"https://nft-1.mypinata.cloud/ipfs/QmTwNwAerqdP3LXcZnCCPyqQzTyB26R5xbsqEy5Vh3h6Dw/\(tokenId).png")!
}

func downloadIpfsImage(_ tokenId:UInt) -> Promise<Media.IpfsImage?> {
  print("Downloading \(tokenId)")
  return contract.ethContract.image(BigUInt(tokenId))
}

func saveToken(_ tokenId : Int) -> Promise<Void> {
  
  downloadImageUrl(url:makeImageUrl(UInt(tokenId)))
    .map { image -> Void in
      print("Downloaded \(tokenId)")
      let filename = getDocumentsDirectory()
        .appendingPathComponent("../")
        .appendingPathComponent("Github")
        .appendingPathComponent("NFTY")
        .appendingPathComponent("DownloadCryptoPunks")
        .appendingPathComponent("Images")
        .appendingPathComponent(collectionName)
        .appendingPathComponent("png")
        .appendingPathComponent("\(tokenId).png")
      try? image.write(to: filename)
    }
    return Promise.value(())
}

var tokenId = 4444 //UserDefaults.standard.integer(forKey: "\(collectionName).startTokenId")
// if (tokenId == 0 || tokenId == totalSize ) { tokenId = 2000 }
var prev : Promise<Int> = Promise.value(tokenId)
print(tokenId)

let parallelCount = 10
while tokenId < totalSize {
  
  // print(tokenId)
  
  let next = prev.then { tokenId -> Promise<Int> in
    print(tokenId)
    UserDefaults.standard.set(tokenId, forKey: "\(collectionName).startTokenId")
    var promises : [Promise<Void>] = []
    var count = 0
    while (tokenId + count) < totalSize && count < parallelCount {
      print(tokenId,count)
      promises.append(saveToken(tokenId + count))
      count+=1
    }
    return when(fulfilled:promises).map { () -> Int in return tokenId + count }
  }
  
  tokenId+=parallelCount
  prev = next
  
}

try? hang(prev)
// .done(on: DispatchQueue.main) { print("Done") }
// .catch(on: DispatchQueue.main) { print($0)}


