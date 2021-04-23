//
//  NFTYApp.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import Firebase

@main
struct NFTYApp: App {
    init() { FirebaseApp.configure() }
  
    var body: some Scene {
        WindowGroup {
          CollectionsView(collections:COLLECTIONS)
        }
    }
}
