//
//  ENSTextChangedViewModel.swift
//  NFTY
//
//  Created by Varun Kohli on 7/3/22.
//

import Foundation

import Web3
import PromiseKit
import SwiftUI

class ENSTextChangedViewModel : ObservableObject {
  
  @Published var recentEvents: [ENSTextChangedFeed.FeedItem] = []
  var recentEventsPublished: Published<[ENSTextChangedFeed.FeedItem]> { _recentEvents }
  var recentEventsPublisher: Published<[ENSTextChangedFeed.FeedItem]>.Publisher { $recentEvents }
  
  @Published var loadMoreState : LoadingState = .uninitialized
  @Published var loadRecentState : LoadingState = .uninitialized
  
  private var fetcher : Promise<ENSTextChangedFeed>
  
  init(key:String,limit:Int) {
    self.fetcher = web3.eth.blockNumber().map { fromBlock in
      ENSTextChangedFeed(key:key,fromBlock:fromBlock.quantity, limit:limit)
    }
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    
    var initialCount = 10
    let initialTotal = 100
    
    switch(self.loadMoreState) {
    case .loading:
      return
    case .uninitialized,.notLoading:
      self.loadMoreState = .loading(LoadingProgress(current:initialCount,total:initialTotal))
    }
    
    var newItems : [ENSTextChangedFeed.FeedItem] = []
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
  
  func getRecentEvents(currentIndex:Int,_ callback : @escaping () -> Void) {
    let thresholdIndex = self.recentEvents.index(self.recentEvents.endIndex, offsetBy: -2)
    // print("getRecentEvents",thresholdIndex,index)
    if currentIndex >= thresholdIndex {
      DispatchQueue.main.async { self.loadMore(callback) }
    } else {
      callback()
    }
  }
  
  func loadLatest(_ callback : @escaping () -> Void) {
    
    var initialCount = 10
    let initialTotal = 100
    
    switch(self.loadRecentState) {
    case .loading:
      return
    case .uninitialized,.notLoading:
      DispatchQueue.main.async {
        self.loadRecentState = .loading(LoadingProgress(current:initialCount,total:initialTotal))
      }
    }
    
    var newItems : [ENSTextChangedFeed.FeedItem] = []
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
