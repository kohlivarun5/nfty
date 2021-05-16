//
//  AddFavSheet.swift
//  NFTY
//
//  Created by Varun Kohli on 5/7/21.
//

import SwiftUI
import Introspect

struct AddFavSheet: View {
  
  class NftWithCollection : ObservableObject {
    
    enum State {
      case empty
      case notFound
      case loading(CollectionInfo)
      case loaded(CollectionInfo,NFTWithLazyPrice)
    }
    
    @Published var state : State = .empty
    
    func update(address:String,tokenId:UInt?) {
      let collection = collectionsFactory.getByAddress(address)
      switch (tokenId,collection) {
      case (.none,_):
        self.state = .empty
      case (_,.none):
        self.state = .empty
      case (.some(let token),.some(let collection)):
        self.state = .loading(collection.info)
        collection.data.contract.getToken(token)
          .done { nftWithPrice in
            self.state = .loaded(collection.info,nftWithPrice)
          }.catch { print ($0) }
      }
    }
  }
  
  private var collectionsDict = collectionsFactory.collections
  @State private var collectionAddress : String = ""
  @State private var tokenId : String = ""
  @State var rank : UInt? = nil
  
  @ObservedObject private var nft : NftWithCollection = NftWithCollection()
  
  private func onChange() {
    nft.update(address:collectionAddress,tokenId:UInt(tokenId))
    UInt(tokenId).map { tokenId in
      collectionsFactory.getByAddress(collectionAddress).map { collection in
        self.rank = collection.info.rarityRank(tokenId)
        print(rank)
      }
    }
  }
  
  var body: some View {
    VStack {
      VStack {
        Text("Add Favorite")
          .font(.title2)
          .fontWeight(.bold)
        Picker("Collection",
               selection:$collectionAddress,
               content: {
                ForEach(collectionsDict.map{$0}, id: \.self.0, content: { (key,collection) in
                  Text(collection.info.name)
                })
               })
          .pickerStyle(SegmentedPickerStyle())
          .onChange(of: collectionAddress) { tag in
            self.onChange()
          }
        
        TextField("Token",text:$tokenId)
          .textContentType(.oneTimeCode)
          .keyboardType(.numberPad)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .introspectTextField { textField in
            textField.becomeFirstResponder()
          }
          .onChange(of: tokenId) { val in
            self.onChange()
          }
        
        switch(nft.state) {
        case .loaded(let info,let nftWithPrice):
          let samples = [info.url1,info.url2,info.url3,info.url4];
          
          ZStack {
            NftImage(nft:nftWithPrice.nft,
                     samples:samples,
                     themeColor:info.themeColor,
                     themeLabelColor:info.themeLabelColor,
                     size:.medium)
              .frame(minHeight: 250)
              .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
              .shadow(color:info.themeColor,radius: 2)
            VStack {
              HStack {
                VStack {
                  Text(rank.map { "RarityRank: \($0)" } ?? "")
                    .font(.footnote)
                    .foregroundColor(Color.gray)
                  Text("")
                    .font(.footnote)
                }
                .padding()
                
                Spacer()
                TokenPrice(price:.lazy(nftWithPrice.indicativePriceWei),color:.dark)
                  .padding()
              }
              Spacer()
            }
          }
          .padding()
          
        case .loading(let info):
          let samples = [info.url1,info.url2,info.url3,info.url4];
          VStack {
            Spacer()
            ZStack {
              
              Image(
                samples[
                  Int.random(in: 0..<samples.count)
                ])
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .background(info.themeColor)
                .blur(radius:20)
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: info.themeColor))
                .scaleEffect(2.0, anchor: .center)
              
            }
            Spacer()
          }
        default:
          Spacer()
        }
        
      }
      .padding()
      .animation(.easeIn)
    }
  }
}

struct AddFavSheet_Previews: PreviewProvider {
  static var previews: some View {
    AddFavSheet()
  }
}
