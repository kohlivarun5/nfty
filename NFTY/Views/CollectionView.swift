//
//  CollectionView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct VisualEffectView: UIViewRepresentable {
  var effect: UIVisualEffect?
  func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
  func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct CollectionView: View {
  
  var collection : CollectionInfo
  
  @State private var showSorted = false
  @State private var filterZeros = false
  @State private var selectedNumber = 0
  
  @State private var action: String? = ""

  
  func sorted(l:[NFT]) -> [NFT] {
    showSorted ? l.sorted(by:{$0.eth < $1.eth}) : l
  }
  func filtered(l:[NFT]) -> [NFT] {
    filterZeros ? l.filter({$0.eth != 0}) : l
  }
  
  struct FillAll: View {
    let color: Color
    
    var body: some View {
      GeometryReader { proxy in
        self.color.frame(width: proxy.size.width * 1.3).fixedSize()
      }
    }
  }
  
  var body: some View {
   
    ScrollView {
      LazyVStack(pinnedViews:[.sectionHeaders]){
        Section(header:
                  ZStack {
                    
                    VisualEffectView(effect: UIBlurEffect(style: .dark))
                      .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                      Picker(selection: $selectedNumber, label: EmptyView()) {
                        Text("Recent").tag(0)
                        Text("Top").tag(1)
                      }
                      .pickerStyle(SegmentedPickerStyle())
                      Toggle(isOn: $showSorted) {
                        Text("Sort Low to High")
                      }
                      Toggle(isOn: $filterZeros) {
                        Text("Filter Zero")
                      }
                    }
                    .padding()
                    
                  }
        ) {
          
          
          ForEach(
            sorted(l:filtered(l:collection.nfts)),id:\.tokenId) { nft in
            let samples = [collection.url1,collection.url2,collection.url3,collection.url4];
            ZStack {
              RoundedImage(nft:nft,samples:samples,themeColor:collection.themeColor)
                .padding()
                .onTapGesture {
                  //perform some tasks if needed before opening Destination view
                  self.action = nft.tokenId
                }
              
              NavigationLink(destination: NftDetail(nft:nft,samples:samples,themeColor:collection.themeColor),tag:nft.tokenId,selection:$action) {}
                .hidden()
            }
          }
        }.textCase(nil)
      }
    }
    .navigationBarTitle(collection.name)
 
  }
}

struct CollectionView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionView(collection:CryptoPunksCollection)
  }
}
