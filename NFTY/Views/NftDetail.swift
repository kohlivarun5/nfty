//
//  NftDetail.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage

struct NftDetail: View {
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
                    .interpolation(.none)    
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.yellow)
                    //.resizable()
                    
                })
                .ignoresSafeArea(edges: .top)
            HStack(alignment: .top) {
                VStack(alignment:.leading) {
                    Text(nft.name)
                        .font(.title)
                    Text("#\(nft.tokenId)")
                        .font(.title2)
                }
                Spacer()
                UsdText(eth:nft.eth)
                        .font(.title)
            }
            .font(.subheadline)
            .padding()
            Spacer()
        }
    }
}

struct NftDetail_Previews: PreviewProvider {
    static var previews: some View {
        NftDetail(nft:nfts[0])
    }
}
