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

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}

func downloadImageUrl(url:URL) -> Data? {
  return try? Data(contentsOf: url)
}

private func makeImageUrl(_ tokenId:UInt) -> URL? {
  return URL(string:"https://api.asciipunks.com/punks/\(tokenId)/rendered.png")
}

func downloadIpfsImage(_ tokenId:UInt) -> Promise<Media.IpfsImage?> {
  print("Downloading \(tokenId)")
  return baycContract.ethContract.image(BigUInt(tokenId))
}


var collectionName = baycContract.name
// let contractAddressHex = "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb"
let totalSize = 10000

var prev : Promise<Void> = Promise.value(())

for tokenId in 0...totalSize {
  
  let next : Promise<Void> =
    prev
    .then {
      downloadIpfsImage(UInt(tokenId))
    }.map { image -> Void in
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
      image.flatMap { try! $0.data.write(to: filename) }
    }
  
  prev = next
}

try? hang(prev)
// .done(on: DispatchQueue.main) { print("Done") }
// .catch(on: DispatchQueue.main) { print($0)}


