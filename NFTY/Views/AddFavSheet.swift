//
//  AddFavSheet.swift
//  NFTY
//
//  Created by Varun Kohli on 5/7/21.
//

import SwiftUI
import Introspect
import BigInt

struct AddFavSheet: View {
  
  class NftWithCollection : ObservableObject {
    
    enum State {
      case empty
      case notFound
      case loading(Collection)
      case loaded(Collection,NFTWithLazyPrice)
    }
    
    @Published var state : State = .empty
    
    func update(address:String,tokenId:UInt?) {
      
      switch (tokenId) {
      case .none:
        self.state = .empty
      case .some(let token):
        collectionsFactory.getByAddress(address)
          .done(on:.main) { collection in
            self.state = .loading(collection)
            let nftWithPrice = collection.contract.getToken(token)
            self.state = .loaded(collection,nftWithPrice)
          }
          .catch { print($0) }
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
    guard let tokenId = BigUInt(tokenId) else { return }
    collectionsFactory.getByAddress(collectionAddress)
      .done(on:.main) { collection in
        self.rank = collection.info.rarityRanking?.getRank(tokenId)
      }.catch { print($0) }
  }
  
  var body: some View {
    
    VStack {
      HStack {
        Spacer()
        Picker(
          selection:$collectionAddress,
          label:
            HStack {
              Text("Select Collection")
                .foregroundColor(.accentColor)
              Text("\(collectionsDict[collectionAddress]?.info.name ?? "")")
                .foregroundColor(.secondary)
            }
          ,
          content: {
            ForEach(collectionsDict.map{$0}.sorted { $0.1.info.name < $1.1.info.name }, id: \.self.0, content: { (key,collection) in
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
      case .loaded(let collection,let nftWithPrice):
        ZStack {
          GeometryReader { metrics in
            NftImage(nft:nftWithPrice.nft,
                     sample:collection.info.sample,
                     themeColor:collection.info.themeColor,
                     themeLabelColor:collection.info.themeLabelColor,
                     size:metrics.size.height < 700 ? .small : .medium,
                     resolution:.hd,
                     favButton:.bottomRight)
            .frame(minHeight: 250)
            .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
          }
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
            }
            Spacer()
            HStack {
              OwnerProfileLinkButton(nft:nftWithPrice.nft,color:collection.info.themeLabelColor, collection: collection)
              Spacer()
            }.padding([.leading,.trailing],15)
          }
        }
        .padding()
        
      case .loading(let collection):
        
        VStack {
          Spacer()
          ZStack {
            
            Image(collection.info.sample)
              .interpolation(.none)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .padding()
              .background(collection.info.themeColor)
              .blur(radius:20)
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: collection.info.themeColor))
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
    .navigationBarTitle("Search",displayMode: .inline)
  }
}

struct AddFavSheet_Previews: PreviewProvider {
  static var previews: some View {
    AddFavSheet()
  }
}
