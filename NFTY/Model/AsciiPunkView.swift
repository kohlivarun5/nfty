//
//  AsciiPunkView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/1/21.
//

import SwiftUI
import URLImage
import PromiseKit

struct AsciiPunkView: View {
  
  @State private var ascii : Media.AsciiPunk? = nil
  
  var asciiPunk : Media.AsciiPunkLazy
  var samples : [String] // TODO Use
  var themeColor : Color
  var body: some View {
    VStack {
      switch(ascii) {
      case .none:
        ZStack {
          Text(String(repeating: "\n", count: 13))
            .font(.system(size:20, design: .monospaced))
            .foregroundColor(Color.systemBackground)
            .padding()
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Color.systemBackground))
            .scaleEffect(2,anchor: .center)
            .padding(.trailing)
        }
      case .some(let ascii):
        Text(ascii.unicode)
          .font(.system(size:20, design: .monospaced))
          .foregroundColor(Color.systemBackground)
          .padding()
      }
    }
    .background(themeColor)
    .onAppear {
      firstly {
        asciiPunk.ascii
      }.done(on:.main) { ascii in
        self.ascii = ascii
      }.catch { print($0) }
    }
  }
}
struct AsciiPunkView_Previews: PreviewProvider {
  static var previews: some View {
    AsciiPunkView(asciiPunk:Media.AsciiPunkLazy(
                    tokenId:0,
                    draw : { tokenId in
                      Promise.value(Media.AsciiPunk(unicode:"↑↑↓↓ ←→←→AB ┌────┐ │ ├┐ │┌ ┌ └│ │ ╘ └┘ │ │ │╙─ │ │ │ └──┘ │ │ │ │ │"))
                    }),
                  samples:SAMPLE_PUNKS,
                  themeColor:Color.secondary)
    }
}
