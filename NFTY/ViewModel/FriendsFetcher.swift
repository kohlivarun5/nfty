//
//  FriendsFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 6/23/22.
//

import Foundation
import Web3
import CoreData
import SwiftUI

class FriendsFetcher : ObservableObject {
  
  @FetchRequest var userFollows : FetchedResults<UserFollow>
  
  init(user:UserWallet?) {
    self._userFollows = FetchRequest(
      entity: UserFollow.entity(),
      sortDescriptors: [],
      predicate: NSPredicate(format: "follower == %@",
                             user?.walletEthAddress?.hex(eip55: true)
                             ?? user?.nearAccount
                             ?? "")
    )
  }
}
