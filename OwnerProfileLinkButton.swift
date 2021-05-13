//
//  OwnerProfileLinkButton.swift
//  NFTY
//
//  Created by Varun Kohli on 5/13/21.
//

import SwiftUI
import Web3

struct UserProfileButton : View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  let address : EthereumAddress?
  let color : Color
  
  var body : some View {
    switch (address.flatMap { addressIfNotZero($0) }) {
    case .none:
      Image(systemName: "flame.fill")
    case .some (let address):
      NavigationLink(
        destination:
          WalletTokensView(tokens: NftOwnerTokens(ownerAddress:address))
          .navigationBarTitle("User Profile")
          .navigationBarBackButtonHidden(true)
          .navigationBarItems(leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }))
      ) {
        Image(systemName: "person.crop.circle")
          .foregroundColor(color)
          .font(.largeTitle)
          .frame(width: 44, height: 44)
      }
    }
  }
}

struct OwnerProfileLinkButton: View {
  let nft:NFT
  let color : Color
  
  var body: some View {
    let collection = collectionsFactory.getByAddress(nft.address)!
    ObservedPromiseView(
      data: ObservablePromise(
        promise:collection.data.contract.ownerOf(nft.tokenId)),
      progress: ProgressView() ) { address in
      UserProfileButton(address: address,color:color)
    }
  }
}

struct OwnerProfileLinkButton_Previews: PreviewProvider {
  static var previews: some View {
    OwnerProfileLinkButton(nft:SampleToken,color:.black)
  }
}
