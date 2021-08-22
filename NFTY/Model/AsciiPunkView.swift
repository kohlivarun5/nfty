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
  let padding : CGFloat
  
  var body: some View {
    switch(ascii) {
    case .none:
      Text(String(repeating: "\n", count: 12))
        .font(.system(size:fontSize, design: .monospaced))
        .foregroundColor(Color.systemBackground)
        .padding(padding)
    case .some(let text):
      Text(text.unicode)
        .font(.system(size:fontSize, weight:.heavy, design: .monospaced))
        .foregroundColor(Color.systemBackground)
        .padding(padding)
    }
  }
  
}

struct AsciiPunkView: View {
  
  @ObservedObject var asciiPunk : ObservablePromise<Media.AsciiPunk?>
  let themeColor : Color
  let fontSize : CGFloat
  let padding : CGFloat?
  var body: some View {
    VStack(spacing:0) {
      Spacer()
      ObservedPromiseView(
        data:asciiPunk,
        progress: {
          ZStack {
            Text(String(repeating: "\n", count: 12))
              .font(.system(size:fontSize, design: .monospaced))
              .foregroundColor(Color.systemBackground)
              .padding([.top,.bottom],padding)
              .padding([.leading,.trailing],15 + (padding ?? 5))
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: Color.tertiarySystemBackground))
              .scaleEffect(2,anchor: .center)
          }}) {
        AsciiText(ascii:$0,fontSize: fontSize,padding:padding ?? 0)
          .padding([.leading,.trailing],15)
      }
      Spacer()
    }
    .background(themeColor)
  }
}

struct AsciiPunkView_Previews: PreviewProvider {
  static var previews: some View {
    AsciiPunkView(asciiPunk:
                    ObservablePromise(resolved:Media.AsciiPunk(unicode:"↑↑↓↓ ←→←→AB ┌────┐ │ ├┐ │┌ ┌ └│ │ ╘ └┘ │ │ │╙─ │ │ │ └──┘ │ │ │ │ │")),
                  themeColor:Color.secondary,
                  fontSize:20,
                  padding: nil)
  }
}
