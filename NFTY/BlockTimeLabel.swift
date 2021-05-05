//
//  BlockTimeLabel.swift
//  NFTY
//
//  Created by Varun Kohli on 5/4/21.
//

import SwiftUI
import BigInt

struct BlockTimeLabel: View {
  let blockNumber : BigUInt?
  
  var body: some View {
    switch(blockNumber) {
    case .none:
      VStack {}
    case .some(let num):
      Text(String(UInt(num)))
    }
  }
}

struct BlockTimeLabel_Previews: PreviewProvider {
  static var previews: some View {
    BlockTimeLabel(blockNumber:nil)
  }
}
