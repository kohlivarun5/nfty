//
//  NFTYgoMacApp.swift
//  NFTYgoMac
//
//  Created by Varun Kohli on 7/10/22.
//

import SwiftUI
import PromiseKit
import BigInt
import Web3
import Web3ContractABI

@main
struct NFTYgoMacApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
            .onAppear {
              let collectionAddress = try! EthereumAddress(hex: "0xe21EBCD28d37A67757B9Bc7b290f4C4928A430b1", eip55: true)
              let collection = MakeErc721Collection.ofName(name:"Saudis",address: collectionAddress)
              let nft = collection.contract.getNFT(100)
            }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        
        
    }
}
