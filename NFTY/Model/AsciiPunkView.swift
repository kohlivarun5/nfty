//
//  AsciiPunkView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/1/21.
//

import SwiftUI

struct AsciiText : View {
  let ascii : Media.AsciiPunk?
  var fontSize : CGFloat
  
  var body: some View {
    switch(ascii) {
    case .none:
      Text(String(repeating: "\n", count: 12))
        .font(.system(size:fontSize, design: .monospaced))
        .foregroundColor(Color.systemBackground)
        .padding()
    case .some(let text):
      Text(text.unicode)
        .font(.system(size:fontSize, weight:.heavy, design: .monospaced))
        .foregroundColor(Color.systemBackground)
        .padding()
    }
  }
  
}

struct AsciiPunkView: View {
  
  @ObservedObject var asciiPunk : ObservablePromise<Media.AsciiPunk?>
  var samples : [String] // TODO Use
  var themeColor : Color
  var fontSize : CGFloat
  var body: some View {
    VStack {
      ObservedPromiseView(
        data:asciiPunk,
        progress: {
          ZStack {
            Text(String(repeating: "\n", count: 12))
              .font(.system(size:fontSize, design: .monospaced))
              .foregroundColor(Color.systemBackground)
              .padding()
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: Color.tertiarySystemBackground))
              .scaleEffect(2,anchor: .center)
          }}) {
        AsciiText(ascii:$0,fontSize: fontSize)
      }
    }
    .background(themeColor)
  }
}

struct AsciiPunkView_Previews: PreviewProvider {
  static var previews: some View {
    AsciiPunkView(asciiPunk:
                    ObservablePromise(resolved:Media.AsciiPunk(unicode:"↑↑↓↓ ←→←→AB ┌────┐ │ ├┐ │┌ ┌ └│ │ ╘ └┘ │ │ │╙─ │ │ │ └──┘ │ │ │ │ │")),
                  
                  samples:SAMPLE_PUNKS,
                  themeColor:Color.secondary,
                  fontSize:20)
  }
}
