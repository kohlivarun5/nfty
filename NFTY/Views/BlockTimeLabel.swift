//
//  BlockTimeLabel.swift
//  NFTY
//
//  Created by Varun Kohli on 5/4/21.
//

import SwiftUI
import BigInt
import Web3

struct BlockTimestampView : View {
  @ObservedObject var block : ObservablePromise<BlockFetcherImpl.BlockInfo?>
  
  var body: some View {
    ObservedPromiseView(data: block, progress: {Text(" ··· ")}) { block in
      Text(
        (block?.timestamp).map { $0.timeAgoDisplay() } ?? " ··· "
      )
    }
  }
}

struct BlockTimeLabel: View {
  let blockNumber : BlockNumber?
  
  init(blockNumber:BlockNumber?) {
    self.blockNumber = blockNumber
  }
  
  var body: some View {
    switch blockNumber {
    case .none:
      Text(" ··· ")
    case .some(let blockNum):
      BlockTimestampView(
        block:BlocksFetcher.getBlock(blockNumber:blockNum))
    }
  }
}

struct BlockTimeLabel_Previews: PreviewProvider {
  static var previews: some View {
    BlockTimeLabel(blockNumber:nil)
  }
}
