//
//  SetENSAvatarConfirmation.swift
//  NFTY
//
//  Created by Varun Kohli on 7/17/22.
//

import SwiftUI

struct SetENSAvatarConfirmation: View {
  
  let selectedAvatarToken : NFTTokenEquatable
  let ensName : String
  
  let walletProvider : WalletProvider
  
  private func onSaveToENS() {
    print("Saving to ENS")
    ENSContract.setAvatar(ensName, from: walletProvider.ethAddress, avatar: selectedAvatarToken.token.nft.nft, eth: web3.eth)
      .then { walletProvider.sendTransaction(tx:$0) }
      .done { print("sendTransactionReturned",$0) } // TODO
      .catch { print("sendTransactionErrored",$0) }
  }
  
  
  var body: some View {
    
    VStack {
      
      ProfileAvatarImage(nft: selectedAvatarToken.token.nft.nft, collection: selectedAvatarToken.token.collection, size: .xxsmall)
        .frame(maxWidth:400)
        .padding(.top,40)
      
      
      HStack {
        Spacer()
        Text("@\(ensName)")
          .font(.title2)
          .foregroundColor(.accentColor)
        Spacer()
      }
      
      Form {
        Section(
          header: HStack {
            Spacer()
            Text("Selected Avatar")
            Spacer()
          },
          content: {
            
            HStack {
              Text("Collection")
              Spacer()
              Text(selectedAvatarToken.token.collection.info.name)
            }
            
            HStack {
              Text("Token ID")
              Spacer()
              Text(String(selectedAvatarToken.token.nft.nft.tokenId))
            }
            
            HStack {
              Button(action: {
                UIImpactFeedbackGenerator(style:.soft)
                  .impactOccurred()
                self.onSaveToENS()
              }) {
                HStack {
                  Spacer()
                  Text("Save Avatar to ENS")
                    .font(.title3)
                    .fontWeight(.bold)
                  Spacer()
                }
              }
              .padding(10)
              .foregroundColor(.black)
              .background(Color.accentColor)
              .cornerRadius(40)
              .padding(10)
            }
          }
        )
      }
    }
  }
  
}
