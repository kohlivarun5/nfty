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
                inProgress: { progress -> Text in  // Display progress
                    /* if let progress = progress {
                        return Text(formatter.string(from: progress as NSNumber) ?? "Loading...")
                    }
                    else { */
                        return Text("Loading...")
                    //}
                },
                failure: { error, retry in         // Display error and retry button
                    VStack {
                        Text(error.localizedDescription)
                        Button("Retry", action: retry)
                    }
                },
                content: { image in                // Content view
                    image
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
        .frame(width: 300.0)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(Color.gray, lineWidth: 4))
        .shadow(radius: 3)
        
    }
}

struct RoundedImage_Previews: PreviewProvider {
    static var previews: some View {
        RoundedImage(nft:nfts[10])
    }
}
