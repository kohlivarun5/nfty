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
  
  let walletProvider : WalletProvider
  
  let account : UserAccount
  @State var ensName : String? = nil
  @State var avatar : (Collection,NFT)? = nil
  
  @State var status : String = ""
  
  private func onSetStatus(_ status:String) {
    print(status)
  }
  
  var body: some View {
    
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
          Text("Update Status")
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
