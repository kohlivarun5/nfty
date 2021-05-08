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
    
    enum State {
      case empty
      case loading
      case notFound
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
        self.state = .loading
        firstly {
          collection.data.contract.getToken(token)
        }.done(on:.main) { nftWithPrice in
          self.state = .loaded(collection.info,nftWithPrice)
        }.catch { error in
          print(error)
          self.state = .notFound
        }
      }
    }
  }
  
  private var collectionsDict = collectionsFactory.collections
  @State private var collectionAddress : String = ""
  @State private var tokenId : String = ""
  
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
          .onChange(of: collectionAddress) { tag in
            nft.update(address:collectionAddress,tokenId:UInt(tokenId))
          }
        
        TextField("Token",text:$tokenId)
          .textContentType(.oneTimeCode)
          .keyboardType(.numberPad)
          .multilineTextAlignment(.center)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .onChange(of: tokenId) { val in
            nft.update(address:collectionAddress,tokenId:UInt(tokenId))
          }
        
        switch(nft.state) {
        case .loaded(let info,let nftWithPrice):
          let samples = [info.url1,info.url2,info.url3,info.url4];
          
          VStack {
            NftImage(nft:nftWithPrice.nft,
                     samples:samples,
                     themeColor:info.themeColor,
                     size:.normal)
              .padding()
              
           
          }.frame(minHeight: 250)
          
          .border(Color.secondary)
          .clipShape(RoundedRectangle(cornerRadius:10, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius:10, style: .continuous).stroke(Color.secondary, lineWidth: 3))
          .shadow(color:Color.primary,radius: 2)
          
        case .loading:
          VStack {
            Spacer()
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(2,anchor: .center)
              .padding()
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


/*
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
 */
