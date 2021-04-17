//
//  NFT.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import Foundation
import SwiftUI

struct NFT: Hashable, Codable {
    var address: String
   var tokenId: String
   var name: String
   var url: URL
   var eth: Double
}

