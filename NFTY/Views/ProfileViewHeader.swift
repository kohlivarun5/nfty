//
//  ProfileViewHeader.swift
//  NFTY
//
//  Created by Varun Kohli on 5/17/22.
//

import SwiftUI
import Web3

struct ProfileViewHeader: View {
  
  let name : String?
  let account : UserAccount
  
  @State private var balance : EthereumQuantity? = nil
  
  var body: some View {
    
    HStack(spacing:0) {
      
      NftImage(
        nft:SampleToken,
        sample:SAMPLE_PUNKS[0],
        themeColor:SampleCollection.info.themeColor,
        themeLabelColor:SampleCollection.info.themeLabelColor,
        size:.xxsmall,
        resolution:.hd,
        favButton:.none)
      .frame(height:120)
      .border(Color.secondary)
      .clipShape(Circle())
      .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
      .shadow(color:.accentColor,radius:0)
      
      VStack(spacing:5) {
        name.map { name in
          HStack {
            Text(name)
              .font(.headline)
            Spacer()
          }
        }
        
        balance.map { wei in
          HStack {
            Spacer()
            UsdEthVText(price:.wei(wei.quantity),fontWeight: .semibold,alignment:.trailing)
              .foregroundColor(.secondary)
          }
        }
        
      }
      .padding(10)
      .background(Color.secondarySystemBackground)
      .cornerRadius(10)
    }
    
    .onAppear {
      if let address = account.ethAddress {
        web3.eth.getBalance(address: address, block:.latest)
          .done(on:.main) { balance in
            self.balance = balance
          }.catch { print($0) }
      }
    }
  }
}
