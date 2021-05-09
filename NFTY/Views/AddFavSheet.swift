//
//  AddFavSheet.swift
//  NFTY
//
//  Created by Varun Kohli on 5/7/21.
//

import SwiftUI
import PromiseKit
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
          .introspectTextField { textField in
            textField.becomeFirstResponder()
          }
          .onChange(of: tokenId) { val in
            nft.update(address:collectionAddress,tokenId:UInt(tokenId))
          }
        
        switch(nft.state) {
        case .loaded(let info,let nftWithPrice):
          let samples = [info.url1,info.url2,info.url3,info.url4];
          
          ZStack {
            NftImage(nft:nftWithPrice.nft,
                     samples:samples,
                     themeColor:info.themeColor,
                     size:.medium)
              .frame(minHeight: 250)
              .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
              .shadow(color:info.themeColor,radius: 2)
            VStack(alignment: .trailing) {
              HStack {
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
