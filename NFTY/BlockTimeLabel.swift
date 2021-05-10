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
  @State private var blockTimeStampString : String = ""
  
  init(blockNumber:BigUInt?) {
    self.blockNumber = blockNumber
  }
  
  var body: some View {
    Text(blockTimeStampString)
    .onAppear {
      DispatchQueue.global(qos:.userInteractive).async {
        switch (self.blockNumber) {
        case .none:
          return
        case .some(let blockNum):
          firstly {
            BlocksFetcher.getBlock(blockNumber:.block(blockNum))
          }.done(on:.main) { block in
            switch(block?.timestamp) {
            case (.none):
              return
            case .some(let timestamp):
              self.blockTimeStampString = Date(timeIntervalSince1970:Double(timestamp.quantity)).timeAgoDisplay()
            }
          }.catch { print ($0) }
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
