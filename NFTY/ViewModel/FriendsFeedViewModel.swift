//
//  FriendsFeedViewModel.swift
//  NFTY
//
//  Created by Varun Kohli on 3/20/22.
//

import Foundation
import Web3
import PromiseKit
import SwiftUI

class FriendsFeedViewModel : ObservableObject {
  
  @Published var recentEvents: [FriendsFeedFetcher.NFTItem] = []
  var recentEventsPublished: Published<[FriendsFeedFetcher.NFTItem]> { _recentEvents }
  var recentEventsPublisher: Published<[FriendsFeedFetcher.NFTItem]>.Publisher { $recentEvents }
  
  @Published var loadMoreState : LoadingState = .uninitialized
  @Published var loadRecentState : LoadingState = .uninitialized
  
  private var fetcher : Promise<FriendsFeedFetcher>
  
  init(from:[EthereumAddress]) {
    self.fetcher = web3.eth.blockNumber().map { fromBlock in
      FriendsFeedFetcher(from: from,fromBlock:fromBlock.quantity )
    }
  }
  
  init(from:EthereumAddress) {
    self.fetcher = web3.eth.blockNumber().map { fromBlock in
      FriendsFeedFetcher(from: [from],fromBlock:fromBlock.quantity )
    }
  }
  
  init(to:EthereumAddress) {
    self.fetcher = web3.eth.blockNumber().map { fromBlock in
      FriendsFeedFetcher(to: [to],fromBlock:fromBlock.quantity )
    }
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    
    var initialCount = 10
    let initialTotal = 100
    
    switch(self.loadMoreState) {
    case .loading:
      return callback()
    case .uninitialized,.notLoading:
      print("Setting loading state in main")
      self.loadMoreState = .loading(LoadingProgress(current:initialCount,total:initialTotal))
    }
    
    var newItems : [FriendsFeedFetcher.NFTItem] = []
    self.fetcher
      .done { fetcher in
        print("Loading friend events")
        fetcher.getRecentEvents(
          onDone:{
            DispatchQueue.main.async {
              self.recentEvents.append(contentsOf: newItems)
              self.loadMoreState = .notLoading
              callback()
              print("Done loading friend events")
            }
          },{
            initialCount = initialCount+1
            DispatchQueue.main.async {
              self.loadMoreState = .loading(LoadingProgress(current:initialCount,total:initialTotal))
            }
          }) { (progress,nft) in
            initialCount = initialCount+1
            newItems.append(nft)
            DispatchQueue.main.async {
              self.loadMoreState = .loading(progress)
            }
          }
      }
      .catch { print($0) }
  }
  
  func getRecentEvents(currentIndex:Int?,_ callback : @escaping () -> Void) {
    guard let index = currentIndex else {
      DispatchQueue.main.async {
        self.loadMore(callback)
      }
      return
    }
    let thresholdIndex = self.recentEvents.index(self.recentEvents.endIndex, offsetBy: -5)
    // print("getRecentEvents",thresholdIndex,index)
    if index >= thresholdIndex {
      DispatchQueue.main.async {
        self.loadMore(callback)
      }
    } else {
      callback()
    }
  }
  
  func loadLatest(_ callback : @escaping () -> Void) {
    
    var initialCount = 10
    let initialTotal = 100
    
    switch(self.loadRecentState) {
    case .loading:
      return callback()
    case .uninitialized,.notLoading:
      DispatchQueue.main.async {
        self.loadRecentState = .loading(LoadingProgress(current:initialCount,total:initialTotal))
      }
    }
    
    var newItems : [FriendsFeedFetcher.NFTItem] = []
    self.fetcher
      .done { fetcher in
        fetcher.refreshLatestEvents(
          onDone:{
            DispatchQueue.main.async {
              self.recentEvents.insert(contentsOf:newItems,at:0)
              self.loadRecentState = .notLoading
              callback()
            }
          }) { (progress,nft) in
            initialCount = initialCount+1
            DispatchQueue.main.async {
              newItems.append(nft)
              self.loadRecentState = .loading(progress)
            }
          }
      }
      .catch { print($0) }
  }
  
}
