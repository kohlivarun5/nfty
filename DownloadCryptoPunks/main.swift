//
//  main.swift
//  RankTokenImages
//
//  Created by Varun Kohli on 4/25/21.
//

import Foundation

print("Hello, World!")

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}

func downloadImageUrl(url:URL) -> Data? {
  return try? Data(contentsOf: url)
}

private func makeImageUrl(_ tokenId:UInt) -> URL? {
  return URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk\(String(format: "%04d", Int(tokenId))).png")
}

var collectionName = "CryptoPunks"
let contractAddressHex = "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb"
let totalSize = 9999 //CryptoPunksCollection.info.totalSupply

for tokenId in 0...totalSize {
  
  let imageUrl = makeImageUrl(UInt(tokenId))
  print(imageUrl);
  switch(imageUrl) {
  case .some(let url):
    let data = downloadImageUrl(url:url)
    let filename = getDocumentsDirectory()
      .appendingPathComponent("../")
      .appendingPathComponent("Github")
      .appendingPathComponent("NFTY")
      .appendingPathComponent("RankTokenImages")
      .appendingPathComponent("Images")
      .appendingPathComponent(collectionName)
      .appendingPathComponent("png")
      .appendingPathComponent("punk\(String(format: "%04d", Int(tokenId))).png")
    data.flatMap { try! $0.write(to: filename) }
  case .none:
    print("Bad URL:\(imageUrl)")
  }
}



