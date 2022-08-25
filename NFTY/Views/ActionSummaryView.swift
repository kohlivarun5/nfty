  //
  //  ActionSummaryView.swift
  //  NFTY
  //
  //  Created by Varun Kohli on 4/10/22.
  //

import SwiftUI

struct ActionSummaryView: View {
  let action : Action
  
  static private func key(account:UserAccount) -> String? {
    switch(account.ethAddress,account.nearAccount) {
    case (.some(let address),_):
      return address.hex(eip55: true)
    case (_,.some(let account)):
      return account
    case (.none,.none):
      return nil
    }
  }
  
  static public func labelOfAccount(account:UserAccount) -> String? {
    let key = ActionSummaryView.key(account: account)
    let userName : String? = key.flatMap {
      let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
      return friends?[$0] ?? account.nearAccount
    }
    switch (userName,account.ethAddress) {
    case (.some(let userName),_):
      return userName
    case (_,.some(let address)):
      return address.hex(eip55: true).trunc(length: 10)
    case (.none, .none):
      return nil
    }
  }
  
  private func labelOfAction(action:Action) -> String {
    return "\(action.action.rawValue)\(action.count > 1 ? " (\(action.count) items)" : "")"
  }
  
  var body: some View {
    
    NavigationLink(
      destination:PrivateCollectionView(account:action.account,isOwnerView:false)
    ) {
      HStack(spacing:0) {
        Text("\(ActionSummaryView.labelOfAccount(account: action.account) ?? "") \(labelOfAction(action:action))")
        Image(systemName: "arrow.right.square.fill").padding(.leading,5)
      }
    }
  }
}
