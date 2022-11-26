  //
  //  UpdateENSStatusView.swift
  //  NFTY
  //
  //  Created by Varun Kohli on 11/25/22.
  //

import SwiftUI


import Web3
import PromiseKit

struct UpdateENSStatusView: View {
  
  @Environment(\.presentationMode) var presentationMode
  
  let walletProvider : WalletProvider
  
  let account : UserAccount
  @State var ensName : String? = nil
  @State var avatar : (Collection,NFT)? = nil
  
  @State var status : String = ""
  
  enum TxState {
    case submitted
    case processing
  }
  
  @State var txState : TxState?
  
  private func onSetStatus(_ status:String) {
    guard let ensName = self.ensName else { return }
    ENSContract.setStatus(ensName, from: walletProvider.ethAddress, status:status, eth: web3.eth)
      .then { tx -> Promise<EthereumData> in
        DispatchQueue.main.async { self.txState = .processing }
        return walletProvider.sendTransaction(tx:tx)
      }
      .done(on:.main) { _ in
        self.txState = .submitted
        presentationMode.wrappedValue.dismiss()
      }
      .catch {
        print("sendTransactionErrored",$0)
        DispatchQueue.main.async {
          self.txState = .submitted
          presentationMode.wrappedValue.dismiss()
        }
      }
  }
  
  var body: some View {
    
    Spacer()
    
    VStack {
      
      HStack(spacing:0) {
        switch (avatar) {
        case .none:
          NftImage(
            nft:SampleToken,
            sample:SAMPLE_PUNKS[0],
            themeColor:SampleCollection.info.themeColor,
            themeLabelColor:SampleCollection.info.themeLabelColor,
            size:.xxsmall,
            resolution:.hd,
            favButton:.none)
          .border(Color.secondary)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
          .shadow(color:.accentColor,radius:0)
          .padding([.leading,.trailing])
          .frame(maxWidth:130)
          .blur(radius: 10)
        case .some(let info):
          let (collection,nft) = info
          NftImage(
            nft:nft,
            sample:collection.info.sample,
            themeColor:collection.info.themeColor,
            themeLabelColor:collection.info.themeLabelColor,
            size:.xxsmall,
            resolution:.hd,
            favButton:.none)
          .border(Color.secondary)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
          .shadow(color:.accentColor,radius:0)
          .padding([.leading,.trailing])
          .frame(maxWidth:130)
        }
        
        VStack(alignment:.leading,spacing:5) {
          
          ensName.map {
            Text($0)
              .lineLimit(1)
              .foregroundColor(Color.accentColor)
          }
          
          Spacer()
          
          TextField("Set Status",text:$status)
            .font(.callout)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .keyboardType(.twitter)
            .introspectTextField { textField in
              textField.becomeFirstResponder()
            }
          
          Spacer()
        }
        .padding(.trailing,10)
      }
      .padding([.top,.bottom])
      .background(Color.secondarySystemBackground)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius:10, style: .continuous).stroke(Color.secondary, lineWidth: 2))
      .shadow(color:.accentColor,radius:0)
      .padding()
      .frame(maxHeight:175)
      
      Button(action: {
        UIImpactFeedbackGenerator(style:.soft)
          .impactOccurred()
        self.onSetStatus(self.status)
      }) {
        HStack {
          Spacer()
          switch(txState) {
          case .processing:
            ProgressView()
          case .submitted,.none:
            Text("Update Status")
              .font(.title3)
              .fontWeight(.bold)
          }
          Spacer()
        }
      }
      .disabled(self.status == "" || self.ensName == nil || self.txState == .processing)
      .padding(10)
      .foregroundColor(.black)
      .background(self.status == "" || self.ensName == nil || self.txState == .processing ? .tertiarySystemBackground : Color.accentColor)
      .cornerRadius(40)
      .padding()
      .padding([.trailing,.leading])
      .padding(.bottom)
      
    }
    .onAppear {
      
      guard let address = account.ethAddress else { return }
      
      ENSWrapper.shared.nameOfOwner(address, eth: web3.eth)
        .done(on:.main) {
          self.ensName = $0
          
          if let _ = avatar { return }
          guard let name = $0 else { return }
            // Also do avatar loading
          ENSWrapper.shared.avatarOfOwner(name, eth: web3.eth)
            .then(on:.main) { avatarOpt -> Promise<ENSTextChangedFeed.NFTItem?> in
              guard let avatar = avatarOpt else { return Promise.value(nil) }
              return ENSTextChangedFeed.parseENSAvatar(avatar:avatar)
            }
            .done(on:.main) {
              $0.map { nftItem in
                withAnimation {
                  self.avatar = (nftItem.collection,nftItem.nft)
                }
              }
            }
            .catch { print($0) }
        }
        .catch { print($0) }
    }
  }
}
