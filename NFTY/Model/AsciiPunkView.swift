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
  var samples : [String]
  var themeColor : Color
  var body: some View {
    VStack {
      switch(ascii) {
      case .none:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(anchor: .center)
          .padding(.trailing)
      case .some(let ascii):
        Text(ascii.unicode)
      }
      URLImage(
        url:URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk0385.png")!,
        options: URLImageOptions(
          expireAfter: 60 * 60 * 24 * 10
        ),
        empty: {
          Text("")
          // This view is displayed before download starts
        },
        inProgress: { progress in
          
          ZStack {
            
            Image(
              samples[
                Int.random(in: 0..<samples.count)
              ])
              .interpolation(.none)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .padding()
              .background(themeColor)
              .blur(radius:20)
            ProgressView(value:progress)
              .progressViewStyle(CircularProgressViewStyle(tint: themeColor))
              .scaleEffect(2.0, anchor: .center)
            
          }
        },
        failure: { error, retry in         // Display error and retry button
          VStack {
            Text(error.localizedDescription)
            Button("Retry", action: retry)
          }
        },
        content: { image in                // Content view
          image
            .interpolation(.none)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding()
            .background(themeColor)
          //.resizable()
          
        })
    }.onAppear {
      firstly {
        asciiPunk.ascii
      }.done(on:.main) { ascii in
        print(ascii?.unicode);
        self.ascii = ascii
      }
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
                  themeColor:CryptoPunksCollection.info.themeColor)
    }
}
