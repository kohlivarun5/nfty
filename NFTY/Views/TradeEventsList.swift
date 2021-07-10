//
//  TradeEventsList.swift
//  NFTY
//
//  Created by Varun Kohli on 7/8/21.
//

import SwiftUI
import BigInt
import Web3


struct TradeEventsList: View {
  
  struct TradeEventsListImpl: View {
    
    @State private var isLoading = true
    
    @ObservedObject var events : NftRecentEventsObject
    
    var body: some View {
      switch(isLoading) {
      case true:
        VStack {
          Spacer()
          ProgressView()
            .scaleEffect(2.0, anchor: .center)
            .onAppear {
              self.events.loadMore {
                DispatchQueue.main.async {
                  self.isLoading = false
                }
              }
            }
          Spacer()
        }
      case false:
        List(events.events,id:\.self.blockNumber.quantity) { event in
          HStack {
            switch(event.value) {
            case 0:
              Text("Transfer")
                .frame(width:120,alignment: .trailing)
                .font(.footnote)
                .foregroundColor(.secondaryLabel)
              Spacer()
              Image(systemName: "arrowshape.zigzag.forward")
            default:
              UsdText(wei:event.value)
                .frame(width:120,alignment: .trailing)
              Spacer()
              Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle")
                
            }
            Spacer()
            BlockTimeLabel(blockNumber: event.blockNumber.quantity)
              .frame(width:120,alignment: .trailing)
          }
          .padding()
          /* .onAppear {
            self.events.getEvents(currentIndex:0);
          } */
        }
        .animation(.default)
      }
      
    }
  }
  let contract : String
  let tokenId : UInt
  
  var body: some View {
    switch(collectionsFactory.getByAddress(contract)?.data.contract.getEventsFetcher(tokenId)) {
    case .none:
      Text("Unavailable")
    case .some(let fetcher):
      TradeEventsListImpl(events: NftRecentEventsObject(fetcher: fetcher))
    }
  }
}

struct TradeEventsList_Previews: PreviewProvider {
  
  class SampleEvents : TokenEventsFetcher {
    func getEvents(onDone: @escaping () -> Void, _ response: @escaping (TradeEvent) -> Void) {
      
      response(TradeEvent(type: TradeEventType.bought, value: BigUInt(0), blockNumber: EthereumQuantity(quantity:BigUInt(10))))
      response(TradeEvent(type: TradeEventType.bought, value: BigUInt(0), blockNumber: EthereumQuantity(quantity:BigUInt(10))))
      response(TradeEvent(type: TradeEventType.bought, value: BigUInt(0), blockNumber: EthereumQuantity(quantity:BigUInt(10))))
      response(TradeEvent(type: TradeEventType.bought, value: BigUInt(0), blockNumber: EthereumQuantity(quantity:BigUInt(10))))
      response(TradeEvent(type: TradeEventType.bought, value: BigUInt(0), blockNumber: EthereumQuantity(quantity:BigUInt(10))))
      response(TradeEvent(type: TradeEventType.bought, value: BigUInt(0), blockNumber: EthereumQuantity(quantity:BigUInt(10))))
      onDone()
    }
    
    
  }
  
  static var previews: some View {
    TradeEventsList(
      contract: SampleToken.address,
      tokenId:SampleToken.tokenId
    )
  }
}
