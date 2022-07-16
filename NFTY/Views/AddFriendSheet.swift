//
//  AddFriendSheet.swift
//  NFTY
//
//  Created by Varun Kohli on 6/4/22.
//

import SwiftUI

struct AddFriendSheet: View {
  
  class UserAccountObservable : ObservableObject {
    
    enum State {
      case empty
      case notFound
      case loaded(UserAccount)
    }
    
    @Published var state : State = .empty
    
    func update(ensName:String) {
      
      switch (ensName.isEmpty) {
      case true:
        self.state = .empty
      case false:
        
        ENSWrapper.shared.nameToOwner(ensName, eth: web3.eth)
          .done(on:.main) { address in
            switch(address) {
            case .none:
              self.state = .notFound
            case .some:
              self.state = .loaded(UserAccount(ethAddress: address, nearAccount: nil))
            }
          }
          .catch { print($0) }
      }
    }
  }
  
  @State private var ensName = ""
  @StateObject private var userAccountState = UserAccountObservable()
  
  var body: some View {
    
    VStack {
      
      TextField("ENS Name",text:$ensName)
        .multilineTextAlignment(.center)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .introspectTextField { textField in
          textField.becomeFirstResponder()
        }
        .onChange(of: ensName) { val in
          self.userAccountState.update(ensName: "\(val.lowercased()).eth")
        }
      
      switch(userAccountState.state) {
      case .loaded(let account):
        VStack {
          Spacer()
          NavigationLink(
            destination:PrivateCollectionView(account:account)
          ) {
            ProfileViewHeader(account: account, isOwnerView: false,addTopPadding:false)
              .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
              .overlay(
                RoundedRectangle(cornerRadius:20, style: .continuous).stroke(Color.secondary, lineWidth: 2))
              .shadow(color:.accentColor,radius:0)
              .padding(10)
          }
          Spacer()
        }
      case .empty:
        Spacer()
      case .notFound:
        VStack {
          Spacer()
          Text("No user found for name\n\(ensName.lowercased()).eth")
            .font(.title)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
          Spacer()
        }
      }
      
    }
    .padding()
    .navigationBarTitle("Search ENS",displayMode: .inline)
  }
}

struct AddFriendSheet_Previews: PreviewProvider {
  static var previews: some View {
    AddFriendSheet()
  }
}
