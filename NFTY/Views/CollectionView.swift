//
//  CollectionView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt

struct VisualEffectView: UIViewRepresentable {
  var effect: UIVisualEffect?
  func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
  func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct CollectionView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  private var info : CollectionInfo
  
  @ObservedObject var recentTrades : NftRecentTradesObject
  
  @State private var showSorted = false
  @State private var filterZeros = true
  @State private var selectedNumber = 0
  
  @State private var action: String? = ""
  
  init(collection:Collection) {
    self.info = collection.info;
    self.recentTrades = collection.data.recentTrades;
  }
  
  
  func sorted(l:[NFT]) -> [NFT] {
    showSorted ? l.sorted(by:{$0.indicativePriceWei! < $1.indicativePriceWei!}) : l
  }
  func filtered(l:[NFT]) -> [NFT] {
    filterZeros ? l.filter({$0.indicativePriceWei != BigUInt(0)}) : l
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
      LazyVStack(pinnedViews:[.sectionHeaders]) {
        Section(/* header:
           ZStack {
           
           VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
           .edgesIgnoringSafeArea(.all)
           
           VStack {
           Picker(selection: $selectedNumber, label: EmptyView()) {
           Text("Recent").tag(0)
           Text("Top").tag(1)
           }
           .pickerStyle(SegmentedPickerStyle())
           .padding()
           }
           
           } */
        ) {
          VStack {
            Toggle(isOn: $showSorted) {
              Text("Sort Low to High")
            }
            Toggle(isOn: $filterZeros) {
              Text("Filter Zero")
            }
          }.padding()
          
          let data = sorted(l:filtered(l:recentTrades.recentTrades));
          ForEach(data.indices,id: \.self) { index in
            let nft = data[index];
            let samples = [info.url1,info.url2,info.url3,info.url4];
            ZStack {
              RoundedImage(nft:nft,samples:samples,themeColor:info.themeColor)
                .padding()
                .onTapGesture {
                  //perform some tasks if needed before opening Destination view
                  self.action = String(nft.tokenId)
                }
              
              NavigationLink(destination: NftDetail(nft:nft,samples:samples,themeColor:info.themeColor,similarTokens:info.similarTokens[safe:Int(nft.tokenId)]),tag:String(nft.tokenId),selection:$action) {}
                .hidden()
            }.onAppear {
              self.recentTrades.getRecentTrades(currentIndex:index);
            }
          }
        }.textCase(nil)
      }.animation(.default)
    }
    .navigationBarTitle(info.name)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }))
    .onAppear {
      self.recentTrades.getRecentTrades(currentIndex: nil);
    }
    
  }
}

struct CollectionView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionView(collection:CryptoPunksCollection)
  }
}
