//
//  FirebaseData.swift
//  NFTY
//
//  Created by Varun Kohli on 4/24/21.
//

import Foundation
import Firebase
import SwiftUI
import Web3


struct FirebaseDb {
  private var firebase: DatabaseReference = Database.database().reference()
  
  private func getFavoritesNode(_ uuid:String) -> DatabaseReference {
    return firebase.child("users").child(uuid).child("favorites")
  }
  
  func observeUserFavorites(onData: @escaping (DataSnapshot) -> Void) {
    if let uuid = UIDevice.current.identifierForVendor?.uuidString {
      getFavoritesNode(uuid).observe(.value,with:onData);
    }
  }
  
  func addFavorite(address:String,tokenId:UInt) {
    if let uuid = UIDevice.current.identifierForVendor?.uuidString {
      getFavoritesNode(uuid).child(address).child(String(tokenId)).setValue(true)
    }
  }
  
}
