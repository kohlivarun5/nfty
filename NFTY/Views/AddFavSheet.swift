//
//  AddFavSheet.swift
//  NFTY
//
//  Created by Varun Kohli on 5/7/21.
//

import SwiftUI
import PromiseKit

struct AddFavSheet: View {
  
  class NftWithCollection : ObservableObject {
    @Published var nft : (CollectionInfo,NFTWithLazyPrice)? = nil
    
    func update(address:String,tokenId:UInt) {
      let collection = collectionsFactory.getByAddress(address)!;
      firstly {
        collection.data.contract.getToken(tokenId)
      }.done(on:.main) { nftWithPrice in
        self.nft = (collection.info,nftWithPrice)
      }.catch { print($0) }
    }
  }
  
  private var collectionsDict = collectionsFactory.collections
  @State private var collectionAddress : String = ""
  @State private var tokenId : Int? = nil
  
  @ObservedObject private var nft : NftWithCollection = NftWithCollection()
  
  
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
          /* .onChange(of: collectionAddress) { tag in
            print(tag)
            // nft.update(address:collectionAddress,tokenId:UInt(tokenId))
          } */
        
        TextField(
          "Token",
          value:$tokenId,
          formatter: NumberFormatter())
          .keyboardType(UIKeyboardType.decimalPad)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          /* .onChange(of: tokenId) { val in
            print(val)
            // nft.update(address:collectionAddress,tokenId:UInt(tokenId))
          } */
        
        switch(nft) {
        case .some(let (info,nftWithPrice)):
          let samples = [info.url1,info.url2,info.url3,info.url4];
          VStack {
            NftImage(nft:nftWithPrice.nft,
                     samples:samples,
                     themeColor:info.themeColor,
                     size:.large)
              .frame(minHeight: 450)
            
            HStack() {
              VStack(alignment:.leading) {
                Text(nftWithPrice.nft.name)
                  .font(.headline)
                Text("#\(nftWithPrice.nft.tokenId)")
                  .font(.subheadline)
              }
              Spacer()
              TokenPrice(price:.lazy(nftWithPrice.indicativePriceWei))
                .font(.title)
            }.padding()
          }
        default:
          Spacer()
        }
      }
      .padding()
    }
  }
}

struct AddFavSheet_Previews: PreviewProvider {
  static var previews: some View {
    AddFavSheet()
  }
}
