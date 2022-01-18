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
  init(address:OpenSeaApi.QueryAddress,side:OpenSeaApi.Side?,emptyMessage:String) {
    self.data = ObservablePromise(promise:OpenSeaApi.userOrders(address:address,side:side))
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

struct ActivityView_Previews: PreviewProvider {
  static var previews: some View {
    ActivityView(address: .maker(SAMPLE_WALLET_ADDRESS),side:nil,emptyMessage: "")
  }
}
