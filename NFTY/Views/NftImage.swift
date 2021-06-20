//
//  NftImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import Kingfisher

struct NftImageImpl: View {
  
  @ObservedObject var url : ObservablePromise<URL>
  var samples : [String]
  var themeColor : Color
  var body: some View {
    
    ObservedPromiseView(
      data:url,
      progress:
        Image(
          samples[
            Int.random(in: 0..<samples.count)
          ])
        .interpolation(.none)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .padding()
        .blur(radius:20)
    ) { url in
      
      KFImage.url(url)
        .placeholder {
          Image(
            samples[
              Int.random(in: 0..<samples.count)
            ])
            .interpolation(.none)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding()
            .blur(radius:20)
        }
        .diskCacheExpiration(.never)
        .loadDiskFileSynchronously()
        .fade(duration: 0.001)
        .interpolation(.none)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .padding()
      
      
    }
  }
}

struct NftImage: View {
  var nft:NFT
  var samples:[String]
  var themeColor : Color
  var themeLabelColor : Color
  
  enum Size {
    case small
    case medium
    case normal
    case large
  }
  
  var size : Size
  
  private func fontSize(_ size:Size) -> CGFloat {
    switch (size) {
    case .small:
      return 8
    case .medium:
      return 16
    case .normal:
      return 18
    case .large:
      return 23
    }
  }
  
  private func autoglyphWidth(_ size:Size) -> CGFloat {
    // Multiples related to 64
    switch (size) {
    case .small:
      return 64
    case .medium:
      return 192
    case .normal:
      return 192
    case .large:
      return 288
    }
  }
  
  private func autoglypPaddingTop(_ size:Size) -> CGFloat? {
    // Multiples related to 64
    switch (size) {
    case .small:
      return nil
    case .medium:
      return nil
    case .normal:
      return 45
    case .large:
      return nil
    }
  }
  
  private func autoglypPaddingBottom(_ size:Size) -> CGFloat? {
    // Multiples related to 64
    switch (size) {
    case .small:
      return nil
    case .medium:
      return nil
    case .normal:
      return 15
    case .large:
      return nil
    }
  }
  
  var body: some View {
    ZStack {
      switch(nft.media){
      case .image(let image):
        NftImageImpl(url:image.url,samples:samples,themeColor:themeColor)
      case .asciiPunk(let asciiPunk):
        AsciiPunkView(asciiPunk:asciiPunk.ascii,samples:samples,themeColor:themeColor,fontSize:fontSize(size))
      case .autoglyph(let autoglyph):
        AutoglyphView(autoglyph:autoglyph.autoglyph,samples:samples,themeColor:themeColor,width:autoglyphWidth(size))
          .padding(.top,autoglypPaddingTop(size))
          .padding(.bottom,autoglypPaddingBottom(size))
      case .ipfsImage(let ipfs):
        ObservedPromiseView(
          data: ipfs.image,
          progress:
            ZStack {
              Image(
                samples[
                  Int.random(in: 0..<samples.count)
                ])
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .blur(radius:20)
              ProgressView()
            }
          ,
          view: { ipfs in
            Image(uiImage: UIImage(data:ipfs!.data)!)
              .interpolation(.none)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .padding()
          })
      }
      //.padding()
      HStack {
        Spacer()
        switch(size) {
        case .normal:
          VStack {
            FavButton(nft:nft,size:.medium,color:themeLabelColor)
            Spacer()
          }
        case .large,.medium:
          VStack {
            Spacer()
            FavButton(nft:nft,size:.large,color:themeLabelColor)
          }
        case .small:
          VStack {
          }
        }
      }
    }.background(themeColor)
  }
}

struct NftImage_Previews: PreviewProvider {
  static var previews: some View {
    NftImage(nft:SampleToken,samples:SAMPLE_PUNKS,themeColor:SampleCollection.info.themeColor,themeLabelColor:SampleCollection.info.themeLabelColor,size:.normal)
  }
}
