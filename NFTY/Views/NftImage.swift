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
  let sample : String
  let themeColor : Color
  var body: some View {
    
    ObservedPromiseView(
      data:url,
      progress: {
        Image(sample)
          .interpolation(.none)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .padding()
          // .colorMultiply([.blue,.green,.orange,.red][Int.random(in: 0..<4)])
          .blur(radius:20)
      }
    ) { url in
      
      KFImage.url(url)
        .placeholder {
          Image(sample)
            .interpolation(.none)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding()
            // .colorMultiply([.blue,.green,.orange,.red][Int.random(in: 0..<4)])
            .blur(radius:20)
        }
        .diskCacheExpiration(.never)
        .fade(duration: 0.001)
        .interpolation(.none)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .padding()
    }
  }
}

struct NftIpfsImageView: View {
  
  @ObservedObject var image : ObservablePromise<Media.IpfsImage?>
  var padding : CGFloat?
  var sample : String
  var body: some View {
    
    ObservedPromiseView(
      data: image,
      progress: {
        ZStack {
          Image(sample)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(padding ?? 0)
            // .colorMultiply([.blue,.green,.orange,.red][Int.random(in: 0..<4)])
            .blur(radius:20)
        }
      },
      view: { ipfs in
        switch(ipfs?.image) {
        case .none:
          ZStack {
            Image(sample)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .padding(padding ?? 0)
              // .colorMultiply([.blue,.green,.orange,.red][Int.random(in: 0..<4)])
              .blur(radius:20)
          }
        case .some(let uiImage):
          Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
            .padding(padding ?? 0)
        }
      })
  }
}

struct NftImage: View {
  var nft:NFT
  var sample:String
  var themeColor : Color
  var themeLabelColor : Color
  
  enum Size {
    case xsmall
    case small
    case medium
    case normal
    case large
  }
  
  var size : Size
  
  private func fontSize(_ size:Size) -> CGFloat {
    switch (size) {
    case .xsmall:
      return 8
    case .small:
      return 13
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
    case .xsmall:
      return 64
    case .small:
      return 180
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
    case .xsmall:
      return nil
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
    case .xsmall:
      return nil
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
  
  private func imagePadding(_ size:Size) -> CGFloat? {
    // Multiples related to 64
    switch (size) {
    case .xsmall:
      return nil
    case .small:
      return nil
    case .medium:
      return 15
    case .normal:
      return 15
    case .large:
      return 10
    }
  }
  
  var body: some View {
    ZStack {
      switch(nft.media){
      case .image(let image):
        NftImageImpl(url:image.url,sample:sample,themeColor:themeColor)
      case .asciiPunk(let asciiPunk):
        AsciiPunkView(
          asciiPunk:asciiPunk.ascii,
          themeColor:themeColor,
          fontSize:fontSize(size),
          padding:imagePadding(size))
      case .autoglyph(let autoglyph):
        AutoglyphView(autoglyph:autoglyph.autoglyph,themeColor:themeColor,width:autoglyphWidth(size))
          .padding(.top,autoglypPaddingTop(size))
          .padding(.bottom,autoglypPaddingBottom(size))
      case .ipfsImage(let ipfs):
        NftIpfsImageView(image:ipfs.image,padding:imagePadding(size), sample:sample)
        
      }
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
        case .xsmall,.small:
          EmptyView()
        }
      }
    }
    .background(themeColor)
  }
}

struct NftImage_Previews: PreviewProvider {
  static var previews: some View {
    NftImage(nft:SampleToken,sample:SAMPLE_PUNKS[0],themeColor:SampleCollection.info.themeColor,themeLabelColor:SampleCollection.info.themeLabelColor,size:.normal)
  }
}
