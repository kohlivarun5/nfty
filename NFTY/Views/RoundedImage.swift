//
//  RoundedImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage

struct RoundedImage: View {
    
    var nft:NFT
    
    var body: some View {
        
        VStack {
            
            URLImage(
                url:nft.url,
                empty: {
                    Text("")
                    // This view is displayed before download starts
                },
                inProgress: { progress in
                  
                  Image("Dracocat")
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .background(Color.yellow)
                    .blur(radius:5)
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
            
            HStack {
                VStack(alignment:.leading) {
                    Text(nft.name)
                    Text("#\(nft.tokenId)")
                }
                Spacer()
                UsdText(eth:nft.eth)
            }
            .font(.subheadline)
            .padding()
        }
        
        .border(Color.secondary)
        .frame(width: 250.0)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(Color.gray, lineWidth: 4))
        .shadow(radius: 3)
        
    }
}

struct RoundedImage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RoundedImage(nft:nfts[10])
            RoundedImage(nft:nfts[0])
        }
    }
}
