//
//  NftImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage

struct NftImage: View {
  var url : URL
  var samples : [String]
  var themeColor : Color
    var body: some View {
      URLImage(
        url:url,
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
        .animation(.default)
      
    }
}

struct NftImage_Previews: PreviewProvider {
    static var previews: some View {
      NftImage(url:URL(string:"SamplePunk1")!,samples:SAMPLE_PUNKS,themeColor:CryptoPunksCollection.themeColor)
    }
}
