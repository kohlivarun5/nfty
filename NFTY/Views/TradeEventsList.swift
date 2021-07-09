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
        ProgressView()
          .onAppear {
            self.events.loadMore {
              DispatchQueue.main.async {
                self.isLoading = false
              }
            }
          }
      case false:
        List(events.events.indices) { index in
          HStack {
            Text("\(Int(events.events[index].blockNumber.quantity))")
            Spacer()
            Text("\(Int(events.events[index].value))")
          }
            .padding()
            .onAppear {
              self.events.getEvents(currentIndex:index);
            }
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
