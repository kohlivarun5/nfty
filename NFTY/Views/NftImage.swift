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
    var body: some View {
      URLImage(
        url:url,
        empty: {
          Text("")
          // This view is displayed before download starts
        },
        inProgress: { progress in
          
          Image(
            samples[
              Int.random(in: 0..<samples.count)
            ])
            .interpolation(.none)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding()
            .background(Color.yellow)
            .blur(radius:7)
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
            .background(Color.yellow)
          //.resizable()
          
        })
      
    }
}

struct NftImage_Previews: PreviewProvider {
    static var previews: some View {
      NftImage(url:URL(string:"SamplePunk1")!,samples:SAMPLE_PUNKS)
    }
}
