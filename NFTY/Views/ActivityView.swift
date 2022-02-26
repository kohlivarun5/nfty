//
//  ActivityView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/9/21.
//

import SwiftUI
import Web3

struct ActivityView: View {
  let emptyMessage : String
  @ObservedObject var data : ObservablePromise<[NFTToken]>
  init(account:UserAccount,kind:UserAccountOffers.Kind,emptyMessage:String) {
    self.data = ObservablePromise(promise:UserAccountOffers.getOffers(account: account, kind: kind))
    self.emptyMessage = emptyMessage
  }
  
  var body: some View {
    ObservedPromiseView(
      data: data,
      progress: {
        VStack {
          Spacer()
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(3,anchor: .center)
            .padding()
          Spacer()
        }
      }) { tokens in
      switch(tokens.isEmpty) {
      case true:
        VStack {
          Spacer()
          Text(emptyMessage)
            .font(.title)
            .foregroundColor(.secondary)
          Spacer()
        }
      case false:
        StaticTokenListView(tokens:tokens)
      }
      
    }
  }
}
