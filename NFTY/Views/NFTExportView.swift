//
//  NFTExportView.swift
//  NFTY
//
//  Created by Varun Kohli on 9/1/21.
//

import SwiftUI

struct NFTExportView: View {
  var nft:NFT
  var sample:String
  var themeColor : Color
  var themeLabelColor : Color
  
  var image : NftImage
  
  @State private var rect: CGRect = .zero
  
  private func onSave() {
    // https://stackoverflow.com/a/64962982
    // https://www.hackingwithswift.com/books/ios-swiftui/how-to-save-images-to-the-users-photo-library
    let image = UIApplication.shared.windows[0].rootViewController?.view.asImage(rect: self.rect)
    image.map { ImageSaver().writeToPhotoAlbum(image: $0) }
  }
  
  init(nft:NFT,sample:String,themeColor:Color,themeLabelColor:Color) {
    self.nft = nft
    self.sample = sample
    self.themeColor = themeColor
    self.themeLabelColor = themeLabelColor
    self.image = NftImage(
      nft:nft,
      sample:sample,
      themeColor:themeColor,
      themeLabelColor:themeLabelColor,
      size:.xlarge,
      resolution:.hd,
      favButton:.none
    )
  }
  
  var body: some View {
    
    ZStack {
      
      VStack {
        Spacer()
        VStack {
          image
            .frame(maxWidth:300)
          /* VStack {
            Text(nft.name)
              .font(.headline)
            Text("#\(nft.tokenId)")
              .font(.subheadline)
          }
          .foregroundColor(themeLabelColor)
 */
        }
        
        Spacer()
      }
      .frame(maxWidth:.infinity,maxHeight:.infinity)
      .background(themeColor)
      .background(RectGetter(rect: $rect))
      
      /*
       VStack {
       Spacer()
       HStack {
       Spacer()
       
       Button(action: {
       UIImpactFeedbackGenerator(style:.soft)
       .impactOccurred()
       onSave()
       }) {
       Text("Save")
       .font(.title3)
       .fontWeight(.bold)
       .padding()
       }
       .foregroundColor(themeColor)
       .background(themeLabelColor)
       .shadow(color:.gray,radius: 5)
       .cornerRadius(40)
       .padding()
       
       Spacer()
       }
       }
       */
      
    }
    
  }
}

struct NFTExportView_Previews: PreviewProvider {
  static var previews: some View {
    NFTExportView(nft: SampleToken, sample: SAMPLE_CCB[0], themeColor: .yellow, themeLabelColor: .black)
  }
}
