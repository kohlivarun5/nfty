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
    VStack(alignment: .leading) {
      HStack {
        Image("SAMPLE_MAYC")
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 100, height: 100)
          .clipped()
          .cornerRadius(10)
        VStack(alignment: .trailing) {
          name.map { Text($0).bold() }
          balance.map { wei in
            UsdEthVText(price:.wei(wei.quantity),fontWeight: .semibold,alignment:.trailing)
              .foregroundColor(.secondary)
          }
        }
        Spacer()
          .onAppear {
            account.ethAddress.map { address in
              web3.eth.getBalance(address: address, block:.latest)
                .done(on:.main) { balance in
                  self.balance = balance
                }.catch { print($0) }
            }
          }
      }
    }
  }
}
