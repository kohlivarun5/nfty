//
//  CollectionsView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct CollectionsView: View {
  
  var collections : [Collection]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  
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
      LazyVStack {
        ForEach(collections,id:\.info.name) { collection in
          ZStack {
            
            VStack{
              VStack {
                HStack {
                  sampleImage(url:collection.info.url1,collection:collection)
                  sampleImage(url:collection.info.url2,collection:collection)
                }
                HStack {
                  sampleImage(url:collection.info.url3,collection:collection)
                  sampleImage(url:collection.info.url4,collection:collection)
                }
              }
              .padding(10)
              .background(collection.info.collectionColor)
              
              
              HStack {
                Text(collection.info.name)
              }
              .font(.headline)
              .padding(.bottom,10)
              
            }
            .border(Color.label)
            .frame(width: 250.0)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(Color.label, lineWidth: 4))
            .padding()
            
            NavigationLink(destination: CollectionView(collection:collection), tag: collection.info.address,selection:$action) {}
              .hidden()
          }
          .onTapGesture {
            //perform some tasks if needed before opening Destination view
            self.action = collection.info.address
          }
        }
      }
    }
  }
}

struct CollectionsView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionsView(collections:COLLECTIONS)
  }
}
