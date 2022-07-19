//
//  SetENSAvatarConfirmation.swift
//  NFTY
//
//  Created by Varun Kohli on 7/17/22.
//

import SwiftUI
import Web3
import PromiseKit

struct SetENSAvatarConfirmation: View {
  
  let selectedAvatarToken : NFTTokenEquatable
  let ensName : String
  
  let walletProvider : WalletProvider
  
  enum TxState {
    case errorTimedOut
    case errorFailed
    case processing
    case processed
  }
  
  @State var txState : TxState? = .processed
  
  private func processTx(txHash:EthereumData,retries:Int, sleepSecs:Double) -> Promise<EthereumTransactionReceiptObject?> {
    return web3.eth.getTransactionReceipt(transactionHash: txHash)
      .then { receipt -> Promise<EthereumTransactionReceiptObject?> in
        
        switch(receipt) {
        case .some(let res):
          return Promise.value(res)
        case .none:
          if (retries > 0) {
            return after(seconds:sleepSecs)
              .then {
                return processTx(txHash: txHash, retries: retries-1, sleepSecs: sleepSecs)
              }
          } else {
            return Promise.value(nil)
          }
        }
      }
  }
  
  private func onSaveToENS() {
    print("Saving to ENS")
    ENSContract.setAvatar(ensName, from: walletProvider.ethAddress, avatar: selectedAvatarToken.token.nft.nft, eth: web3.eth)
      .then { walletProvider.sendTransaction(tx:$0) }
      .then(on:.main) { txHash -> Promise<EthereumTransactionReceiptObject?> in
        self.txState = .processing
        return processTx(txHash: txHash, retries: 300, sleepSecs: 0.1) // 30 seconds wait
      }
      .done(on:.main) {
        switch($0) {
        case .none:
          self.txState = .errorTimedOut
        case .some:
          self.txState = .processed
        }
      }
      .catch(on:.main) {
        print("sendTransactionErrored",$0)
        self.txState = .errorFailed
      }
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
          }
        )
      }
      
      
      switch(txState) {
      case .none:
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
      case .some(.errorTimedOut):
        Text("Transaction timed-out")
          .foregroundColor(.accentColor)
          .font(.title3)
          .fontWeight(.bold)
      case .some(.errorFailed):
        Text("Failed to process transaction")
          .foregroundColor(.accentColor)
          .font(.title3)
          .fontWeight(.bold)
      case .some(.processing):
        ProgressView("Processing transaction")
      case .some(.processed):
        Text("Transaction successful")
          .foregroundColor(.accentColor)
          .font(.title3)
          .fontWeight(.bold)
      }
    }
    .padding(.bottom,20)
  }
  
}
