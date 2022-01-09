//
//  ConnectWalletSheet.swift
//  NFTY
//
//  Created by Varun Kohli on 5/9/21.
//

import SwiftUI
import Web3

struct UserWalletConnectorView : View {
  
  @ObservedObject var userWallet: UserWallet
  @State var isConnecting = false
  
  var body: some View {
    VStack(spacing:20) {
      
      switch(userWallet.walletConnectSession,isConnecting) {
      case (.none,true):
        VStack {
          ProgressView()
            .scaleEffect(2.0, anchor: .center)
            .frame(width: 80,height:80)
          Text("Connecting...")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      case (.none,false),(.some,_):
        HStack(spacing:30) {
          Spacer()
          
          VStack {
            Text("Sign-in using")
              .foregroundColor(.secondary)
              .font(.subheadline)
              .bold()
            
            HStack {
              
              
              Button(action:{
                UIImpactFeedbackGenerator(style: .light)
                  .impactOccurred()
                self.userWallet.removeWalletConnectSession()
                self.isConnecting = true
                try! userWallet.connectToWallet(scheme:"metamask:")
              }) {
                VStack {
                  Image("Metamask")
                    .resizable()
                    .frame(width: 60,height:60)
                  
                  Text("MetaMask")
                    .font(.caption)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.orange)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .border(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .overlay(
                  RoundedRectangle(cornerRadius:20, style: .continuous)
                    .stroke(Color.orange, lineWidth: 1))
              }
              
              Button(action:{
                UIImpactFeedbackGenerator(style: .light)
                  .impactOccurred()
                self.userWallet.removeWalletConnectSession()
                self.isConnecting = true
                try! userWallet.connectToWallet(scheme:"trust:")
              }) {
                VStack {
                  Image("TrustWallet")
                    .resizable()
                    .frame(width: 60,height:60)
                  
                  Text("Trust Wallet")
                    .font(.caption)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.blue)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .border(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .overlay(
                  RoundedRectangle(cornerRadius:20, style: .continuous)
                    .stroke(Color.blue, lineWidth: 1))
              }
            }
          }
          Spacer()
        }
        
        switch(userWallet.signedIn,userWallet.walletConnectSession?.walletInfo?.peerMeta.name) {
        case (false,_),(_,.none):
          EmptyView()
        case (true,.some(let wallet)):
          Text("Currently signed-in using \(wallet)")
            .foregroundColor(.secondary)
            .font(.caption)
            .italic()
        }
        
      }
    }
    .padding()
  }
  
}

struct ConnectWalletSheet: View {
  
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var userWallet: UserWallet
  
  @State var badAddressError : String = ""
  
  var body: some View {
    VStack {
      Spacer()
      UserWalletConnectorView(userWallet:userWallet)
      
      ZStack {
        Divider()
        Text("OR")
          .font(.caption).italic()
          .foregroundColor(.secondaryLabel)
          .padding(.trailing)
          .padding(.leading)
          .background(Color.systemBackground)
      }
      
      VStack {
        Text("Add Wallet using Address")
          .font(.title2)
          .fontWeight(.bold)
        
        Text("")
          .font(.title2)
        
        Button(action: {
          if let string = UIPasteboard.general.string {
            // text was found and placed in the "string" constant
            switch(try? EthereumAddress(hex:string,eip55: false)) {
            case .none:
              self.badAddressError = "Invalid Address Pasted"
            case .some(let address):
              self.badAddressError = ""
              userWallet.saveWalletAddress(address:address)
              presentationMode.wrappedValue.dismiss()
            }
          }
        }) {
          
          HStack(spacing:50) {
            Spacer()
            VStack {
              Image(systemName: "doc.on.clipboard")
                .font(.title)
              Text("Paste from clipboard")
                .fontWeight(.semibold)
                .font(.subheadline)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.black)
            .background(Color.accentColor)
            .cornerRadius(40)
            
            Spacer()
          }
        }
        
        Text(badAddressError)
          .font(.footnote)
          .foregroundColor(.secondary)
          .animation(.easeIn)
      }
      .padding()
      
      Spacer()
    }
  }
}

class ConnectWalletSheet_Previews: PreviewProvider {
  @State static private var address : EthereumAddress? = nil
  static var previews: some View {
    ConnectWalletSheet(userWallet:UserWallet())
  }
}
