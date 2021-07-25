//
//  ConnectWalletSheet.swift
//  NFTY
//
//  Created by Varun Kohli on 5/9/21.
//

import SwiftUI
import Web3

struct ConnectWalletSheet: View {
  
  @Environment(\.presentationMode) var presentationMode
  
  @Binding var address : EthereumAddress?
  @State var badAddressError : String = ""
  
  @State var badImportWalletError : String = ""
  
  enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case failed
  }
  
  @State var connection : ConnectionState = .disconnected
  @State var walletConnect: WalletConnect?
  
  // private var walletConnect : WalletConnect
  
  
  var body: some View {
    VStack {
      Spacer()
      
      VStack {
        
        
        Text("Connect Wallet")
          .font(.title2)
          .fontWeight(.bold)
        
        Text("")
          .font(.title2)
        
        HStack(spacing:30) {
          
          Spacer()
          switch(walletConnect) {
          case .none:
            ProgressView()
          case .some(let walletConnect):
            switch(connection) {
            case .failed,.disconnected:
              HStack {
                
                Button(action:{
                  UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()

                  let url = try! walletConnect.connectToWallet(link:"metamask:")
                  // we need a delay so that WalletConnectClient can send handshake request
                  DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(5000)) {
                    print("Launching=\(url)")
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                  }
                  self.connection = .connecting
                  
                }) {
                  VStack {
                    Image("Metamask")
                      .resizable()
                      .frame(width: 60,height:60)
                    
                    Text("Connect using MetaMask")
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
                  
                  let url = try! walletConnect.connectToWallet(link:"trust:")
                  // we need a delay so that WalletConnectClient can send handshake request
                  DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                    print("Launching=\(url)")
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                  }
                  self.connection = .connecting
                }) {
                  VStack {
                    Image("TrustWallet")
                      .resizable()
                      .frame(width: 60,height:60)
                    
                    Text("Connect using Trust Wallet")
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
              
            case .connecting:
              ProgressView()
                .scaleEffect(2.0, anchor: .center)
                .frame(width: 80,height:80)
            case .connected:
              VStack {
                Image("Metamask")
                  .resizable()
                  .frame(width: 60,height:60)
                
                Text("Connected using MetaMask")
                  .font(.caption)
                  .fontWeight(.bold)
                  .multilineTextAlignment(.center)
                  .foregroundColor(Color.orange)
              }
            }
          }
          
          Spacer()
        }
        
        
        Text(badImportWalletError)
          .font(.footnote)
          .foregroundColor(.secondary)
      }
      .padding()
      .animation(.easeIn)
      
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
        Text("Save Wallet Address")
          .font(.title2)
          .fontWeight(.bold)
        
        Text("")
          .font(.title2)
        
        Button(action: {
          if let string = UIPasteboard.general.string {
            // text was found and placed in the "string" constant
            print(string)
            self.address = try? EthereumAddress(hex:string,eip55: false)
            if (self.address == nil) {
              self.badAddressError = "Invalid Address Pasted"
            } else {
              self.badAddressError = ""
              NSUbiquitousKeyValueStore.default.set(string, forKey:CloudDefaultStorageKeys.walletAddress.rawValue)
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
            .foregroundColor(.white)
            .background(Color.gray)
            .cornerRadius(40)
            
            Spacer()
          }
        }
        
        Text(badAddressError)
          .font(.footnote)
          .foregroundColor(.secondary)
      }
      .padding()
      .animation(.easeIn)
      
      Spacer()
    }
    .onAppear {
      self.walletConnect = WalletConnect(delegate:self)
    }
  }
}


extension ConnectWalletSheet: WalletConnectDelegate {
  func failedToConnect() {
    print("failedToConnect")
    self.connection = ConnectionState.failed
  }
  
  func didConnect(account:EthereumAddress?) {
    print("didConnect")
    self.connection = ConnectionState.connected
    self.address = account
    switch(self.address) {
    case .none:
      self.badAddressError = "Imported bad address"
    case .some(let account):
      self.badAddressError = ""
      NSUbiquitousKeyValueStore.default.set(account.hex(eip55:true), forKey:CloudDefaultStorageKeys.walletAddress.rawValue)
      presentationMode.wrappedValue.dismiss()
    }
  }
  
  func didDisconnect() {
    print("didDisconnect")
    self.connection = ConnectionState.disconnected
  }
}

class ConnectWalletSheet_Previews: PreviewProvider {
  @State static private var address : EthereumAddress? = nil
  static var previews: some View {
    ConnectWalletSheet(address:$address)
  }
}
