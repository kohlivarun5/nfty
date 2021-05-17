//
//  AddressLabel.swift
//  NFTY
//
//  Created by Varun Kohli on 5/17/21.
//

import SwiftUI

struct AddressLabel: View {
  let address : String
  let maxLen : Int
  
  var body: some View {
    Text(address.trunc(length:maxLen))
      .font(.system(size:12, design: .monospaced))
      .foregroundColor(.secondary)
  }
}

struct AddressLabel_Previews: PreviewProvider {
  static var previews: some View {
    AddressLabel(address:"0x0",maxLen:30)
  }
}
