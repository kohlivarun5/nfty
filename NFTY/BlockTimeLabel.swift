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

let CachedNow = Date()

extension Date {
  func timeAgoDisplay() -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: self, relativeTo: CachedNow)
  }
}

struct BlockTimeLabel: View {
  let blockNumber : BigUInt?
  @State private var blockTimeStampString : String = ""
  
  init(blockNumber:BigUInt?) {
    self.blockNumber = blockNumber
  }
  
  var body: some View {
    Text(blockTimeStampString)
    .onAppear {
      DispatchQueue.global(qos:.utility).async {
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
              self.blockTimeStampString = Date(timeIntervalSince1970:Double(timestamp.quantity)).timeAgoDisplay()
            }
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
