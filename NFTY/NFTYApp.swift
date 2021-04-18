//
//  NFTYApp.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

@main
struct NFTYApp: App {
    var body: some Scene {
        WindowGroup {
          CollectionsView(collections:COLLECTIONS)
        }
    }
}
