//
//  FeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/3/21.
//

import SwiftUI
import BigInt

// https://prafullkumar77.medium.com/how-to-making-pure-swiftui-pull-to-refresh-b497d3639ee5
// https://stackoverflow.com/a/65100922
struct PullToRefresh: View {
  
  var coordinateSpaceName: String
  var onRefresh: ()->Void
  
  @State var needRefresh: Bool = false
  
  var body: some View {
    GeometryReader { geo in
      if (geo.frame(in: .named(coordinateSpaceName)).midY > 50) {
        Spacer()
          .onAppear {
            needRefresh = true
          }
      } else if (geo.frame(in: .named(coordinateSpaceName)).maxY < 10) {
        Spacer()
          .onAppear {
            if needRefresh {
              needRefresh = false
              onRefresh()
            }
          }
      }
      HStack {
        Spacer()
        if needRefresh {
          ProgressView()
            .scaleEffect(1.5, anchor: .center)
        } else {
          EmptyView()
        }
        Spacer()
      }
    }.padding(.top, -50)
  }
}

struct FeedView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @ObservedObject var trades : CompositeRecentTradesObject
  
  enum RefreshButton {
    case hidden
    case loading
    case loaded
  }
  @State private var refreshButton : RefreshButton = .hidden
  @State private var action: String? = ""
  @State private var isLoading = true
  
  init(trades:CompositeRecentTradesObject) {
    self.trades = trades;
  }
  
  private func triggerRefresh() {
    self.refreshButton = .loading
    self.trades.loadLatest() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.refreshButton = .loaded }
      
      // trigger refresh again after 30 seconds
      // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
    }
  }
  
  var body: some View {
    
    VStack {
      switch(isLoading) {
      case true:
        ScrollView {
          LazyVStack {
            let sampleInfos = [
              CompositeCollection.loaders[0].collection.info,
              CompositeCollection.loaders[3].collection.info,
              CompositeCollection.loaders[4].collection.info,
              CompositeCollection.loaders[5].collection.info,
            ]
            
            ForEach(sampleInfos.indices,id:\.self) { index in
              let info = sampleInfos[index]
              ZStack {
                
                VStack {
                  ZStack {
                    
                    Image(info.sample)
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
                  
                  HStack {
                    Spacer()
                  }
                  .font(.subheadline)
                  .padding()
                }
                
                .border(Color.secondary)
                .frame(width:250)
                .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                .overlay(
                  RoundedRectangle(cornerRadius:20, style: .continuous).stroke(Color.secondary, lineWidth: 2))
              }
              .padding()
            }
          }
        }
      case false:
        ScrollView {
          PullToRefresh(coordinateSpaceName: "RefreshControl") {
            self.triggerRefresh()
            let impactMed = UIImpactFeedbackGenerator(style: .light)
            impactMed.impactOccurred()
          }
          LazyVStack {
            ForEach(trades.recentTrades.indices,id:\.self) { index in
              let item = trades.recentTrades[index]
              let nft = item.nft.nftWithPrice

              ZStack {
                                
                RoundedImage(
                  nft:nft.nft,
                  price:nft.indicativePriceWei,
                  collection:item.collection,
                  width: .normal
                )
                .shadow(color:.accentColor,radius:item.isNew ? 10 : 0)
                .padding()
                .onTapGesture {
                  //perform some tasks if needed before opening Destination view
                  self.action = "\(nft.nft.address):\(nft.nft.tokenId)"
                }
                
                NavigationLink(destination: NftDetail(
                  nft:nft.nft,
                  price:nft.indicativePriceWei,
                  collection:item.collection,
                  hideOwnerLink:false,selectedProperties:[]
                ),tag:"\(nft.nft.address):\(nft.nft.tokenId)",selection:$action) {}
                .hidden()
              }.onAppear {
                DispatchQueue.global(qos:.userInitiated).async {
                  self.trades.getRecentTrades(currentIndex:index) {}
                }
              }
            }
            .textCase(nil)
          }
        }.coordinateSpace(name: "RefreshControl")
      }
    }
    .navigationBarItems(
      trailing:
        HStack {
          switch refreshButton {
          case .hidden:
            EmptyView()
          case .loading:
            ProgressView()
          case .loaded:
            Button(action: {
              self.triggerRefresh()
              let impactMed = UIImpactFeedbackGenerator(style: .light)
              impactMed.impactOccurred()
            }) {
              Image(systemName:"arrow.clockwise.circle.fill")
                .font(.title3)
                .foregroundColor(.accentColor)
                .padding(10)
            }
          }
        }
    )
    .onAppear {
      if (self.isLoading) {
        self.trades.getRecentTrades(currentIndex: 0) {
          DispatchQueue.main.async {
            self.isLoading = false
            self.refreshButton = .loaded
            // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
          }
        } 
      }
    }
    
  }
}


struct FeedView_Previews: PreviewProvider {
  static var previews: some View {
    FeedView(trades:CompositeCollection)
  }
}
