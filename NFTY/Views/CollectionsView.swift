//
//  CollectionsView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct CollectionsView: View {
  
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  var collections : [CompositeRecentTradesObject.CollectionLoader]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  
  @State private var action: String? = nil
  
  private func sampleImage(url:String,collection:Collection) -> some View {
    Image(url)
      .interpolation(.none)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .cornerRadius(20)
  }
  
  var body: some View {
    ScrollView {
      
      LazyVGrid(
        columns: Array(
          repeating:GridItem(.flexible(maximum:160)),
          count:horizontalSizeClass == .some(.compact) ? 2 : 3)
      ) {
        
        ForEach(collections,id:\.collection.info.name) { loader in
          ZStack {
            
            VStack {
              sampleImage(url:loader.collection.info.sample,collection:loader.collection)
                .padding(10)
                .background(loader.collection.info.themeColor)
              
              
              HStack {
                Text(loader.collection.info.name)
              }
              .font(.headline)
              .padding(.bottom,10)
              
            }
            .border(Color.label)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.label, lineWidth: 2))
            .shadow(color:.secondary,radius:5)
            //.padding()
            
            NavigationLink(destination: CollectionView(
              collection:loader.collection,
              info:loader.collection.info,
              loader:loader,
              page:.recent), tag: loader.collection.info.address,selection:$action) {}
              .hidden()
          }
          .padding([.leading,.trailing],8)
          .padding([.top,.bottom],10)
          .onTapGesture {
            //perform some tasks if needed before opening Destination view
            self.action = loader.collection.info.address
          }
        }
      }
    }
    .navigationBarItems(
      trailing:
        NavigationLink(destination: AddFavSheet()) {
          Image(systemName:"magnifyingglass.circle.fill")
            .font(.title3)
            .foregroundColor(.accentColor)
            .padding(10)
        }
    )
  }
}

struct CollectionsView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionsView(collections:CompositeCollection.loaders)
  }
}
