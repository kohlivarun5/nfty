//
//  BlockTimeLabel.swift
//  NFTY
//
//  Created by Varun Kohli on 5/4/21.
//

import SwiftUI
import BigInt
import Web3
import PromiseKit

extension Date {
  func timeAgoDisplay() -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: self, relativeTo: Date())
  }
}

struct BlockTimeLabel: View {
  let blockNumber : BigUInt?
  @State private var blockTimeStamp : EthereumQuantity?
  
  var body: some View {
    VStack {
      switch(blockTimeStamp?.quantity) {
      case .none:
        VStack {}
      case .some(let timestamp):
        Text(Date(timeIntervalSince1970:Double(timestamp)).timeAgoDisplay())
      }
    }.onAppear {
      switch (blockNumber) {
      case .none:
        return
      case .some(let blockNumber):
        firstly {
          BlocksFetcher.getBlock(blockNumber: .block(blockNumber))
        }.done(on:.main) { block in
          switch(block?.timestamp) {
          case (.none):
            return
          case .some(let timestamp):
            self.blockTimeStamp = timestamp
          }
        }
      }
    }
  }
}

struct BlockTimeLabel_Previews: PreviewProvider {
  static var previews: some View {
    BlockTimeLabel(blockNumber:nil)
  }
}
