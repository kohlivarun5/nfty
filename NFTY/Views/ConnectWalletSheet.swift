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
  
  var body: some View {
    VStack {
      Spacer()
      
      VStack {
        
        
        
        Button(action: {
        }) {
          
          HStack(spacing:50) {
            Spacer()
            VStack {
              Image(systemName: "at.badge.plus")
                .font(.title)
              Text("Create New Wallet")
                .font(.title3)
                .fontWeight(.bold)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(40)
            
            Spacer()
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
        
        
        Text("Import Wallet")
          .font(.title2)
          .fontWeight(.bold)
        
        Text("")
          .font(.title2)
        
        HStack(spacing:30) {
          
          Spacer()
          Button(action: {
            
            if let string = UIPasteboard.general.string {
              // text was found and placed in the "string" constant
              print(string)
            }
            
          }) {
            
            VStack {
              Image(systemName: "doc.on.clipboard")
                .font(.title)
              Text("Paste seed phrase")
                .font(.caption)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.orange)
            .cornerRadius(40)
          }
          
          Button(action: {
            if let string = UIPasteboard.general.string {
              // text was found and placed in the "string" constant
              print(string)
            }
          }) {
            
            
            VStack {
              Image(systemName: "doc.on.clipboard")
                .font(.title)
              Text("Paste privatekey")
                .font(.caption)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.orange)
            .cornerRadius(40)
            
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
