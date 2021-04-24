//
//  CollectionsView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct CollectionsView: View {
  
  var collections : [String:Collection]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  
  private func sampleImage(url:String,collection:Collection) -> some View {
    Image(url)
      .interpolation(.none)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .padding(collection.info.samplePadding)
  }
   
  var body: some View {
    NavigationView {
      List {
        ForEach(collections.map {$0.value},id:\.info.name) { collection in
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
              .background(collection.info.themeColor)
                           
              
              HStack {
                Text(collection.info.name)
              }
              .font(.headline)
              .padding()
              
            }
            .border(Color.secondary)
            .frame(width: 250.0)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(Color.gray, lineWidth: 4))
            .shadow(radius: 3)
            .padding()
            
            NavigationLink(destination: CollectionView(collection:collection)) {}
              .hidden()
          }
        }
      }
      .navigationBarTitle("Collections")
      .navigationBarItems(trailing: NavigationLink(destination: FavoritesView()) {
        Image(systemName: "heart.circle")
          .font(.system(size: 28))
          //.imageScale(.large)
          .frame(width: 44, height: 44, alignment: .trailing)
          .foregroundColor(.red)
      })
      .ignoresSafeArea(edges: .top)
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}

struct CollectionsView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionsView(collections:COLLECTIONS)
  }
}
