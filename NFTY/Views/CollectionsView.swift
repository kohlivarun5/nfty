//
//  CollectionsView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct CollectionsView: View {
  
  @State private var showSorted = false
  @State private var filterZeros = false
  
  func sorted(l:[NFT]) -> [NFT] {
    showSorted ? l.sorted(by:{$0.eth < $1.eth}) : l
  }
  func filtered(l:[NFT]) -> [NFT] {
    filterZeros ? l.filter({$0.eth != 0}) : l
  }
  
  var body: some View {
    NavigationView {
      List {
        Toggle(isOn: $showSorted) {
          Text("Sort Low to High")
        }
        Toggle(isOn: $filterZeros) {
          Text("Filter Zero")
        }
        
        ForEach(
          sorted(l:filtered(l:nfts)),id:\.tokenId) { nft in
          ZStack {
            RoundedImage(nft:nft)
              .padding()
            NavigationLink(destination: NftDetail(nft:nft)) {}
              .hidden()
          }
        }
      }
      .navigationBarTitle("Collections")
      .ignoresSafeArea(edges: .top)
    }
    
    
  }
}

struct CollectionsView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionView()
  }
}
