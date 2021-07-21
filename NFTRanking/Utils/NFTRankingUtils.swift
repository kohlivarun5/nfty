//
//  NFTRankingUtils.swift
//  NFTY
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation

func getDocumentsDirectory() -> URL {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}


func getImageFileName(_ collectionName:String,_ tokenId:UInt) -> URL {
  return
    getDocumentsDirectory()
    .appendingPathComponent("../")
    .appendingPathComponent("Github")
    .appendingPathComponent("NFTY")
    .appendingPathComponent("data")
    .appendingPathComponent("Images")
    .appendingPathComponent(collectionName)
    .appendingPathComponent("png")
    .appendingPathComponent("\(tokenId).png")
  
}
