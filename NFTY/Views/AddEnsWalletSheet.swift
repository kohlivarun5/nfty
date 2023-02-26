  //
  //  AddEnsWalletSheet.swift
  //  NFTY
  //
  //  Created by Varun Kohli on 2/26/23.
  //

import SwiftUI

struct AddEnsWalletSheet: View {
  
  class UserAccountObservable : ObservableObject {
    
    enum State {
      case empty
      case notFound
      case loaded(UserAccount)
    }
    
    enum EntryType {
      case ens
      case near
    }
    
    @Published var state : State = .empty
    
    static func dotSuffix(entryType:EntryType) -> String {
      switch entryType {
      case .ens:
        return ".eth"
      case .near:
        return ".near"
      }
    }
    
    func update(name:String,entryType:EntryType) {
      
      let dotSuffixStr = UserAccountObservable.dotSuffix(entryType: entryType)
      
      let suffixed = "\(name.lowercased())\(dotSuffixStr)"
      
      switch (name.isEmpty,entryType) {
      case (true,_):
        self.state = .empty
      case (false,.ens):
        ENSWrapper.shared.nameToOwner(suffixed, eth: web3.eth)
          .done(on:.main) { address in
            switch(address) {
            case .none:
              self.state = .notFound
            case .some:
              self.state = .loaded(UserAccount(ethAddress: address, nearAccount: nil))
            }
          }
          .catch { print($0) }
      case (false,.near):
        self.state = .loaded(UserAccount(ethAddress: nil, nearAccount: suffixed))
      }
    }
  }
  
  
  @Environment(\.presentationMode) var presentationMode
  @State private var ensName = ""
  @StateObject private var userAccountState = UserAccountObservable()
  
  let onSelect : ((UserAccount) -> (Void))
  
  let entryType : UserAccountObservable.EntryType
  
  
  
  var body: some View {
    
    let dotSuffixStr = UserAccountObservable.dotSuffix(entryType: self.entryType)
    VStack {
      
      TextField("Enter \(dotSuffixStr)",text:$ensName)
        .multilineTextAlignment(.center)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .introspectTextField { textField in
          textField.becomeFirstResponder()
        }
        .onChange(of: ensName) { val in
          self.userAccountState.update(name:val,entryType:entryType)
        }
      
      switch(userAccountState.state) {
      case .loaded(let account):
        VStack {
          Spacer()
          ProfileViewHeader(account: account, isOwnerView: false,addTopPadding:false)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius:20, style: .continuous).stroke(Color.secondary, lineWidth: 2))
            .shadow(color:.accentColor,radius:0)
            .padding(10)
          Spacer()
        }
        .onTapGesture {
          onSelect(account)
          presentationMode.wrappedValue.dismiss()
        }
      case .empty:
        Spacer()
      case .notFound:
        VStack {
          Spacer()
          Text("No user found for name\n\(ensName.lowercased())\(dotSuffixStr)")
            .font(.title)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
          Spacer()
        }
      }
      
    }
    .padding()
    .navigationBarTitle("Search \(dotSuffixStr)",displayMode: .inline)
  }
}
