//
//  BlockTimeLabel.swift
//  NFTY
//
//  Created by Varun Kohli on 5/4/21.
//

import SwiftUI
import BigInt
import Web3

extension Date {
  func timeAgoDisplay() -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: self, relativeTo: Date())
  }
}

struct BlockTimestampView : View {
  @ObservedObject var timestamp : ObservablePromise<String?>
  
  var body: some View {
    ObservedPromiseView(data: timestamp, progress: Text("...    ")) { timestamp in
      Text(timestamp ?? "...    ")
      
    }
  }
}

struct BlockTimeLabel: View {
  let blockNumber : BigUInt?
  
  init(blockNumber:BigUInt?) {
    self.blockNumber = blockNumber
  }
  
  var body: some View {
    switch blockNumber {
    case .none:
      Text("...    ")
    case .some(let blockNum):
      BlockTimestampView(
        timestamp:ObservablePromise(
          promise:BlocksFetcher.getBlock(blockNumber:.block(blockNum)).compactMap { block in
            return (block?.timestamp).map { Date(timeIntervalSince1970:Double($0.quantity)).timeAgoDisplay() }
          }
        ))
    }
  }
}

struct BlockTimeLabel_Previews: PreviewProvider {
  static var previews: some View {
    BlockTimeLabel(blockNumber:nil)
  }
}
