//
//  TradeEventsList.swift
//  NFTY
//
//  Created by Varun Kohli on 7/8/21.
//

import SwiftUI
import BigInt
import Web3


struct TradeEventIcon {
  static func systemName(_ type:TradeEventType) -> String {
    switch (type) {
    case .bought:
      return "arrow.up.right.and.arrow.down.left.rectangle"
    case .bid:
      return "hand.point.up.left"
    case .ask:
      return "target"
    case .minted:
      return "sparkles"
    case .transfer:
      return "arrowshape.zigzag.forward"
    }
  }
}

struct TradeEventIconView : View {
  
  let type : TradeEventType
  
  var body: some View {
    switch (type) {
    case .bought:
      VStack(spacing:5) {
        Image(systemName: TradeEventIcon.systemName(type))
        Text("Sale")
          .font(.footnote)
          .foregroundColor(.secondaryLabel)
      }
    case .bid:
      VStack(spacing:5) {
        Image(systemName: TradeEventIcon.systemName(type))
        Text("Bid")
          .font(.footnote)
          .foregroundColor(.secondaryLabel)
      }
    case .ask:
      VStack(spacing:5) {
        Image(systemName: TradeEventIcon.systemName(type))
        Text("Ask")
          .font(.footnote)
          .foregroundColor(.secondaryLabel)
      }
    case .minted:
      VStack(spacing:5) {
        Image(systemName: TradeEventIcon.systemName(type))
        Text("Minted")
          .font(.footnote)
          .foregroundColor(.secondaryLabel)
      }
    case .transfer:
      VStack(spacing:5) {
        Image(systemName: TradeEventIcon.systemName(type))
        /* Text("")
         .font(.footnote)
         .foregroundColor(.secondaryLabel) */
      }
    }
  }
}

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
          
          VStack {
            
            switch(event.value,event.type) {
            case (0,.bought):
              HStack {
                Text("Transfer")
                  .frame(width:120,alignment: .trailing)
                Spacer()
                TradeEventIconView(type:.transfer)
                Spacer()
                BlockTimeLabel(blockNumber: event.blockNumber.quantity)
                  .frame(width:120,alignment: .trailing)
              }
              .foregroundColor(.secondaryLabel)
              .font(.footnote)
            case (0,_):
              HStack {
                Text("")
                  .frame(width:120,alignment: .trailing)
                Spacer()
                TradeEventIconView(type:event.type)
                Spacer()
                BlockTimeLabel(blockNumber: event.blockNumber.quantity)
                  .frame(width:120,alignment: .trailing)
              }
              .foregroundColor(event.type == .bought || event.type == .minted ? .label : .secondary)
            default:
              HStack {
                UsdText(wei:event.value,fontWeight: event.type == .bought ? .semibold : nil)
                  .frame(width:120,alignment: .trailing)
                Spacer()
                TradeEventIconView(type:event.type)
                Spacer()
                BlockTimeLabel(blockNumber: event.blockNumber.quantity)
                  .frame(width:120,alignment: .trailing)
              }
              .foregroundColor(event.type == .bought || event.type == .minted ? .label : .secondary)
            }
          }
          .padding(5)
        }
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
