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
        let nftWithPrice = collection.data.contract.getToken(token)
        self.state = .loaded(collection.info,nftWithPrice)
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
        self.rank = collection.info.rarityRanking?.getRank(tokenId)
      }
    }
  }
  
  var body: some View {
    VStack {
      VStack {
        Text("Search NFT")
          .font(.title2)
          .fontWeight(.bold)
        HStack {
          Spacer()
          Picker(
            selection:$collectionAddress,
            label:
              HStack {
                Text("Select Collection")
                  .foregroundColor(.orange)
                Text("\(collectionsDict[collectionAddress]?.info.name ?? "")")
                  .foregroundColor(.secondary)
              }
            ,
            content: {
              ForEach(collectionsDict.map{$0}, id: \.self.0, content: { (key,collection) in
                Text(collection.info.name)
              })
            }
          )
          .pickerStyle(MenuPickerStyle())
          .onChange(of: collectionAddress) { tag in self.onChange() }
          Spacer()
        }
        .animation(.none)
        .padding(.bottom,5)
        
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
          ZStack {
            NftImage(nft:nftWithPrice.nft,
                     sample:info.sample,
                     themeColor:info.themeColor,
                     themeLabelColor:info.themeLabelColor,
                     size:.medium)
              .frame(minHeight: 250)
              .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
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
          
          VStack {
            Spacer()
            ZStack {
              
              Image(info.sample)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                // .colorMultiply([.blue,.green,.orange,.red][Int.random(in: 0..<4)])
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
