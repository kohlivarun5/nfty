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
  
   
  var body: some View {
    NavigationView {
      List {
        ForEach(collections,id:\.name) { collection in
          ZStack {
            
            VStack{
              VStack {
                HStack {
                  Image(collection.url1)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit).padding()
                    .background(Color.yellow)
                    .blur(radius:2)
                  
                  Image(collection.url2)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit).padding()
                    .background(Color.yellow)
                    .blur(radius:2)
                  
                }
                HStack {
                  Image(collection.url2)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit).padding()
                    .background(Color.yellow)
                    .blur(radius:2)
                  Image(collection.url3)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit).padding()
                    .background(Color.yellow)
                    .blur(radius:2)
                }
              }
              .background(Color.yellow)
              
              
              
              HStack {
                Text(collection.name)
              }
              .font(.subheadline)
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
