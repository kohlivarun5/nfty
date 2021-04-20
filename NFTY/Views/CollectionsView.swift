//
//  CollectionsView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct CollectionsView: View {
  
  var collections : [CollectionInfo]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  
  private func sampleImage(url:String,collection:CollectionInfo) -> some View {
    Image(url)
      .interpolation(.none)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .padding(collection.samplePadding)
  }
   
  var body: some View {
    NavigationView {
      List {
        ForEach(collections,id:\.name) { collection in
          ZStack {
            
            VStack{
              VStack {
                HStack {
                  sampleImage(url:collection.url1,collection:collection)
                  sampleImage(url:collection.url2,collection:collection)
                }
                HStack {
                  sampleImage(url:collection.url3,collection:collection)
                  sampleImage(url:collection.url4,collection:collection)
                }
              }
              .background(collection.themeColor)
                           
              
              HStack {
                Text(collection.name)
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
