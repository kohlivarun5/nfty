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
  return URL(string:"https://api.asciipunks.com/punks/\(tokenId)/rendered.png")
}

var collectionName = "AsciiPunks"
// let contractAddressHex = "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb"
let totalSize = 1704 //CryptoPunksCollection.info.totalSupply

for tokenId in 1...totalSize {
  
  let imageUrl = makeImageUrl(UInt(tokenId))
  print(imageUrl);
  switch(imageUrl) {
  case .some(let url):
    let data = downloadImageUrl(url:url)
    let filename = getDocumentsDirectory()
      .appendingPathComponent("../")
      .appendingPathComponent("Github")
      .appendingPathComponent("NFTY")
      .appendingPathComponent("DownloadCryptoPunks")
      .appendingPathComponent("Images")
      .appendingPathComponent(collectionName)
      .appendingPathComponent("png")
      .appendingPathComponent("\(tokenId).png")
    data.flatMap { try! $0.write(to: filename) }
  case .none:
    print("Bad URL:\(imageUrl)")
  }
}



