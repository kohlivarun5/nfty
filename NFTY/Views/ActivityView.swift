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
  init(address:OpenSeaApi.QueryAddress,side:OpenSeaApi.Side?) {
    self.data = ObservablePromise(promise:OpenSeaApi.userOrders(address:address,side:side))
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
      }) {
      StaticTokenListView(nfts: $0)
    }
  }
}

struct ActivityView_Previews: PreviewProvider {
  static var previews: some View {
    ActivityView(address: .maker(SAMPLE_WALLET_ADDRESS),side:nil)
  }
}
