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
  }
  
  
  var body: some View {
    
    VStack {
      Spacer()
      
      ProfileAvatarImage(nft: selectedAvatarToken.token.nft.nft, collection: selectedAvatarToken.token.collection, size: .xxsmall)
        .frame(maxWidth:400)
      
      
      Form {
        Section(
          header: Text(""),
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
