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
        HStack {
          Spacer()
          
          VStack {
            HStack(spacing:20) {
              
              let config = [
                (title:"MetaMask",image:"Metamask",color:Color.orange,scheme:"metamask:"),
                (title:"Trust Wallet",image:"TrustWallet",color:Color.blue,scheme:"trust:"),
                (title:"Rainbow",image:"RainbowWallet",color:Color(red:200/255,green:230/255,blue:80/255),scheme:"rainbow:"),
              ];
              
              ForEach(config,id:\.self.title) { item in
                let (title,image,color,scheme) = item;
                Button(action:{
                  UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
                  self.userWallet.removeWalletConnectSession()
                  self.isConnecting = true
                  try! userWallet.connectToWallet(scheme:scheme)
                }) {
                  VStack {
                    Image(image)
                      .resizable()
                      .frame(width: 50,height:50)
                    
                    Text(title)
                      .font(.caption)
                      .fontWeight(.bold)
                      .multilineTextAlignment(.center)
                      .foregroundColor(color)
                  }
                  .padding()
                  .border(color)
                  .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                  .overlay(
                    RoundedRectangle(cornerRadius:20, style: .continuous)
                      .stroke(color, lineWidth: 3))
                }
                
              }
            }
          }
          Spacer()
        }
        
        switch(userWallet.signedIn,userWallet.walletConnectSession?.walletInfo?.peerMeta.name) {
        case (false,_),(_,.none):
          EmptyView()
        case (true,.some(let wallet)):
          Text("Currently connected to \(wallet)")
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
      VStack {
        Text("Add Wallet")
          .font(.title2)
          .fontWeight(.bold)
          .padding(.bottom,10)
        
        HStack {
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
            
            VStack {
              Image(systemName: "doc.on.clipboard")
                .font(.title)
              VStack(spacing:0) {
                Text("Paste")
                  .fontWeight(.semibold)
                  .font(.subheadline)
                Text("ETH address")
                  .fontWeight(.semibold)
                  .font(.subheadline)
              }
              
            }
              //.frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.black)
            .background(Color.accentColor)
            .cornerRadius(40)
          }
          
          
          Button(action: {
            if let string = UIPasteboard.general.string {
                // text was found and placed in the "string" constant
              print("Pasted near address=\(string)")
              if (!string.lowercased().hasSuffix("near")) {
                self.badAddressError = "Invalid Address Pasted"
              } else {
                self.badAddressError = ""
                userWallet.saveNearAccount(account:string)
                presentationMode.wrappedValue.dismiss()
              }
            }
          }) {
            VStack {
              Image(systemName: "doc.on.clipboard")
                .font(.title)
              VStack(spacing:0) {
                Text("Paste")
                  .fontWeight(.semibold)
                  .font(.subheadline)
                Text("NEAR address")
                  .fontWeight(.semibold)
                  .font(.subheadline)
              }
              
            }
              //.frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.black)
            .background(Color.accentColor)
            .cornerRadius(40)
          }
          
        }
        
        Text(badAddressError)
          .font(.footnote)
          .foregroundColor(.secondary)
          .animation(.easeIn)
      }
      .padding()
      
      ZStack {
        Divider()
        Text("OR")
          .font(.caption).italic()
          .foregroundColor(.secondaryLabel)
          .padding(.trailing)
          .padding(.leading)
          .background(Color.systemBackground)
      }
      
      
      UserWalletConnectorView(userWallet:userWallet)
      
      
      
      
      
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
