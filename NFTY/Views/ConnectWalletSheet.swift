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
  @EnvironmentObject var userWallet: UserWallet
  
  @State var badAddressError : String = ""
  
  enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case failed
  }
  
  @State var connection : ConnectionState = .disconnected
  
  var body: some View {
    VStack {
      Spacer()
      
      VStack(spacing:20) {
        
        switch(userWallet.walletConnectSession) {
        case .none:
          ProgressView()
        case .some(let session):
          switch(connection) {
          case .connecting:
            VStack {
              ProgressView()
                .scaleEffect(2.0, anchor: .center)
                .frame(width: 80,height:80)
              Text("Connecting...")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          case .failed,.disconnected,.connected:
            HStack(spacing:30) {
              Spacer()
              
              HStack {
                Button(action:{
                  UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
                  
                  let url = try! userWallet.connectToWallet(link:"trust:")
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
              Spacer()
            }
            
            if (connection == .failed) {
              VStack {
                Text("Failed to connect")
                  .font(.footnote)
                  .foregroundColor(.secondary)
                Text("Please try again")
                  .font(.footnote)
                  .foregroundColor(.secondary)
              }
            }
          }
        }
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
        Text("Add Wallet using Address")
          .font(.title2)
          .fontWeight(.bold)
        
        Text("")
          .font(.title2)
        
        Button(action: {
          if let string = UIPasteboard.general.string {
            // text was found and placed in the "string" constant
            print(string)
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
            .foregroundColor(.white)
            .background(Color.green)
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
  }
}

class ConnectWalletSheet_Previews: PreviewProvider {
  @State static private var address : EthereumAddress? = nil
  static var previews: some View {
    ConnectWalletSheet()
  }
}
