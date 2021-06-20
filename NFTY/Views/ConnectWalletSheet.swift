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
  
  @State var metamaskLoading = true
  
  @State var badImportWalletError : String = ""
  
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
          Button(action: {
            
            metamaskLoading.toggle()
            
            UIImpactFeedbackGenerator(style: .light)
              .impactOccurred()
            
            if let string = UIPasteboard.general.string {
              // text was found and placed in the "string" constant
              print(string)
            }
            
          }) {
            
            (metamaskLoading
              ? AnyView(
                ProgressView()
                  .scaleEffect(2.0, anchor: .center)
                  .frame(width: 80,height:80)
              )
              
              : AnyView(
                
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
              )
            ).frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .border(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius:20, style: .continuous)
                .stroke(Color.orange, lineWidth: 1))
          }
          
          Button(action: {
            
            UIImpactFeedbackGenerator(style: .light)
              .impactOccurred()
            
            if let string = UIPasteboard.general.string {
              // text was found and placed in the "string" constant
              print(string)
            }
            
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
  }
}

class ConnectWalletSheet_Previews: PreviewProvider {
  @State static private var address : EthereumAddress? = nil
  static var previews: some View {
    ConnectWalletSheet(address:$address)
  }
}
