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
                    .interpolation(.low)
                    .resizable()
                    .aspectRatio(contentMode: .fit).padding()
                    .background(collection.themeColor)
                    .blur(radius:collection.blur)
                    .scaleEffect(collection.sampleScaling, anchor: .center)
                  
                  Image(collection.url2)
                    .interpolation(.low)
                    .resizable()
                    .aspectRatio(contentMode: .fit).padding()
                    .background(collection.themeColor)
                    .blur(radius:collection.blur)
                    .scaleEffect(collection.sampleScaling, anchor: .center)
                  
                }
                HStack {
                  Image(collection.url3)
                    .interpolation(.low)
                    .resizable()
                    .aspectRatio(contentMode: .fit).padding()
                    .background(collection.themeColor)
                    .blur(radius:collection.blur)
                    .scaleEffect(collection.sampleScaling, anchor: .center)
                  Image(collection.url4)
                    .interpolation(.low)
                    .resizable()
                    .aspectRatio(contentMode: .fit).padding()
                    .background(collection.themeColor)
                    .blur(radius:collection.blur)
                    .scaleEffect(collection.sampleScaling, anchor: .center)
                }
              }
              .background(collection.themeColor)
              
              
              
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
