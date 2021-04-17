//
//  ListView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct ListView: View {
    var body: some View {
        List(nfts,id:\.tokenId) { nft in
            ZStack {
                RoundedImage(nft:nft)
                NavigationLink(destination: NftDetail(nft:nft)) {}
                .hidden()
               
            }
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
    }
}
