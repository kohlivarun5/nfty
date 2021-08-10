//
//  ActivityView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/9/21.
//

import SwiftUI
import Web3

struct ActivityView: View {
  @ObservedObject var data : ObservablePromise<[NFTWithLazyPrice]>
  init(address:EthereumAddress) {
    self.data = ObservablePromise(promise:OpenSeaApi.userOrders(maker: address))
  }
  
  var body: some View {
    ObservedPromiseView(
      data: data,
      progress: {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(3,anchor: .center)
          .padding()
      }) {
      StaticTokenListView(nfts: $0)
    }
  }
}

struct ActivityView_Previews: PreviewProvider {
  static var previews: some View {
    ActivityView(address: SAMPLE_WALLET_ADDRESS)
  }
}
