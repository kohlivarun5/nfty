//
//  CollectionsView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct CollectionsView: View {
  
  var collections : [CollectionInfo]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  
  
  var body: some View {
    NavigationView {
      List {
        ForEach(collections,id:\.name) { collection in
          ZStack {
            RoundedImage(nft:CrypotPunksNfts[0])
              .padding()
            NavigationLink(destination: CollectionView(collection:collection)) {}
              .hidden()
          }
        }
      }
      .navigationBarTitle("Collections")
      .ignoresSafeArea(edges: .top)
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}

struct CollectionsView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionsView(collections:COLLECTIONS)
  }
}
