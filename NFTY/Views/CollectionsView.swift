//
//  CollectionsView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct CollectionsView: View {
  
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  var collections : [Collection]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  
  @State private var showAddFavSheet = false
  
  @State private var action: String? = nil
  
  private func sampleImage(url:String,collection:Collection) -> some View {
    Image(url)
      .interpolation(.none)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .cornerRadius(10)
  }
  
  var body: some View {
    ScrollView {
      
      LazyVGrid(
        columns: Array(
          repeating:GridItem(.flexible(maximum:200)),
          count:horizontalSizeClass == .some(.compact) ? 2 : 4)
      ) {
        
        ForEach(collections,id:\.info.name) { collection in
          ZStack {
            
            VStack {
              sampleImage(url:collection.info.sample,collection:collection)
                .padding(10)
                .background(collection.info.collectionColor)
              
              
              HStack {
                Text(collection.info.name)
              }
              .font(.headline)
              .padding(.bottom,10)
              
            }
            .border(Color.label)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.label, lineWidth: 2))
            .shadow(color:.secondary,radius:10)
            //.padding()
            
            NavigationLink(destination: CollectionView(collection:collection), tag: collection.info.address,selection:$action) {}
              .hidden()
          }
          .padding()
          .onTapGesture {
            //perform some tasks if needed before opening Destination view
            self.action = collection.info.address
          }
        }
      }
    }
    .navigationBarItems(
      trailing:
        Button(action: {
          self.showAddFavSheet = true
        }) {
          Image(systemName:"magnifyingglass.circle.fill")
            .font(.title3)
            .foregroundColor(.orange)
            .padding(10)
        }
    )
    .sheet(isPresented: $showAddFavSheet) { AddFavSheet() }
  }
}

struct CollectionsView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionsView(collections:COLLECTIONS)
  }
}
