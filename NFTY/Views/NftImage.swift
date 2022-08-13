//
//  NftImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import AVKit

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
          .colorMultiply(.tertiarySystemBackground)
          .blur(radius:20)
      }
    ) { url in
      AsyncImage(url: url, content: {
        $0
          .interpolation(.none)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .padding()
      }, placeholder: {
        Image(sample)
          .interpolation(.none)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .padding()
          .colorMultiply(.tertiarySystemBackground)
          .blur(radius:20)
      })      
      .shadow(color:.black,radius: 10)
    }
  }
}

enum NftImageResolution {
  case hd
  case normal
}

struct NftIpfsImageView: View {
  
  @StateObject var image : ObservablePromise<Media.IpfsImage?>
  
  let resolution : NftImageResolution
  
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
            .colorMultiply(.tertiarySystemBackground)
            .blur(radius:20)
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
        }
      },
      view: { ipfs in
        switch(ipfs) {
        case .none:
          ZStack {
            Image(sample)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .padding(padding ?? 0)
              .colorMultiply(.tertiarySystemBackground)
              .blur(radius:20)
            Image(systemName: "exclamationmark.triangle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .padding(80)
              .foregroundColor(.tertiaryLabel)
          }
        case .some(let image):
          switch(resolution) {
          case .normal:
            switch image.image {
            case .image(let image):
              Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .padding(padding ?? 0)
            case .svg(let svg):
              svg
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .padding(padding ?? 0)
            case .video(let url):
              VideoLoopPlayer(url: url)
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .padding(padding ?? 0)
            }
          case .hd:
            switch image.image_hd {
            case .image(let image_hd):
              Image(uiImage: image_hd)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .padding(padding ?? 0)
            case .svg(let svg):
              svg
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .padding(padding ?? 0)
            case .video(let url):
              VideoLoopPlayer(url: url)
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .padding(padding ?? 0)
            }
          }
        }
      })
  }
}

struct NftImage: View {
  let nft:NFT
  let sample:String
  let themeColor : Color
  let themeLabelColor : Color
  
  enum Size {
    case xxsmall
    case xsmall
    case small
    case medium
    case normal
    case large
    case xlarge
  }
  
  enum FavButtonLocation {
    case topRight
    case bottomRight
    case none
  }
  
  let size : Size
  let resolution : NftImageResolution
  let favButton : FavButtonLocation
  
  private func fontSize(_ size:Size) -> CGFloat {
    switch (size) {
    case .xxsmall:
      return 6
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
    case .xlarge:
      return 25
    }
  }
  
  private func autoglyphWidth(_ size:Size) -> CGFloat {
    // Multiples related to 64
    switch (size) {
    case .xxsmall,.xsmall:
      return 64
    case .small:
      return 120
    case .medium:
      return 192
    case .normal:
      return 192
    case .large,.xlarge:
      return 288
    }
  }
  
  private func autoglypPaddingTop(_ size:Size) -> CGFloat? {
    // Multiples related to 64
    switch (size) {
    case .xxsmall,.xsmall:
      return nil
    case .small:
      return nil
    case .medium:
      return nil
    case .normal:
      return 45
    case .large,.xlarge:
      return nil
    }
  }
  
  private func autoglypPaddingBottom(_ size:Size) -> CGFloat? {
    // Multiples related to 64
    switch (size) {
    case .xxsmall,.xsmall:
      return nil
    case .small:
      return nil
    case .medium:
      return nil
    case .normal:
      return 15
    case .large,.xlarge:
      return nil
    }
  }
  
  private func imagePadding(_ size:Size) -> CGFloat? {
    // Multiples related to 64
    switch (size) {
    case .xxsmall,.xsmall:
      return nil
    case .small:
      return nil
    case .medium:
      return 10
    case .normal:
      return 15
    case .large:
      return 10
    case .xlarge:
      return 20
    }
  }
  
  private func asciiPunkPadding(_ size:Size) -> CGFloat? {
    // Multiples related to 64
    switch (size) {
    case .xxsmall,.xsmall,.small,.medium,.normal,.xlarge:
      return nil
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
          padding:asciiPunkPadding(size))
      case .autoglyph(let autoglyph):
        AutoglyphView(autoglyph:autoglyph.autoglyph,themeColor:themeColor,width:autoglyphWidth(size))
          .padding(.top,autoglypPaddingTop(size))
          .padding(.bottom,autoglypPaddingBottom(size))
      case .ipfsImage(let ipfs):
        NftIpfsImageView(image:ipfs.image,resolution:resolution,padding:imagePadding(size), sample:sample)
      }
      
      HStack {
        Spacer()
        switch(favButton) {
        case .topRight:
          VStack(spacing:0) {
            FavButton(nft:nft,size:.large,color:themeLabelColor)
            Spacer()
          }
        case .bottomRight:
          VStack(spacing:0) {
            Spacer()
            FavButton(nft:nft,size:.large,color:themeLabelColor)
          }
        case .none:
          EmptyView()
        }
      }
    }
    .background(themeColor)
  }
}

struct NftImage_Previews: PreviewProvider {
  static var previews: some View {
    NftImage(nft:SampleToken,sample:SAMPLE_PUNKS[0],themeColor:SampleCollection.info.themeColor,themeLabelColor:SampleCollection.info.themeLabelColor,size:.normal,resolution:.hd,favButton:.topRight)
  }
}
