//
//  ActionSummaryView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/10/22.
//

import SwiftUI

struct ActionSummaryView: View {
  let action : Action
  
  private func key(account:UserAccount) -> String? {
    switch(account.ethAddress,account.nearAccount) {
    case (.some(let address),_):
      return address.hex(eip55: true)
    case (_,.some(let account)):
      return account
    case (.none,.none):
      return nil
    }
  }
  
  private func labelOfAccount(account:UserAccount) -> String? {
    let key = key(account: account)
    return key.flatMap {
      let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
      return friends?[$0] ?? account.nearAccount
    }
  }
  
  private func labelOfAction(action:Action.ActionType) -> String {
    switch(action) {
    case .sold:
      return "sold"
    case .bought:
      return "bought"
    case .minted:
      return "minted"
    }
  }
  
  var body: some View {
    
    NavigationLink(
      destination:PrivateCollectionView(account:action.account)
    ) {
      HStack(spacing:0) {
        labelOfAccount(account: action.account)
          .map { AnyView(Text($0)) }
        ?? (action.account.ethAddress?.hex(eip55: true)).map { AnyView(AddressLabel(address:$0,maxLen: 10)) }
        Text(" \(labelOfAction(action:action.action))")
        Image(systemName: "arrow.right.square.fill").padding(.leading,5)
      }
    }
  }
}
