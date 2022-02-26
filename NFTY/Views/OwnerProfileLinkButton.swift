//
//  OwnerProfileLinkButton.swift
//  NFTY
//
//  Created by Varun Kohli on 5/13/21.
//

import SwiftUI
import Web3

struct UserProfileButton : View {
  
  let account : UserAccount?
  
  var body : some View {
    switch (account) {
    case .none:
      EmptyView()
    case .some (let account):
      NavigationLink(
        destination:PrivateCollectionView(account:account)
      ) {
        Image(systemName: "person.crop.circle")
          .font(.largeTitle)
          .frame(width: 44, height: 44)
      }
    }
  }
}

struct OwnerProfileLinkButton: View {
  let nft:NFT
  let color : Color
  let collection : Collection
  
  var body: some View {
    ObservedPromiseView(
      data: ObservablePromise(
        promise:collection.contract.ownerOf(nft.tokenId)),
      progress: { ProgressView() } ) { account in
      UserProfileButton(account: account)
    }.foregroundColor(color)
  }
}

struct OwnerProfileLinkButton_Previews: PreviewProvider {
  static var previews: some View {
    OwnerProfileLinkButton(nft:SampleToken,color:.black,collection:SampleCollection)
  }
}
