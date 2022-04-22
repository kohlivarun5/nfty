//
//  FriendsFeedViewModel.swift
//  NFTY
//
//  Created by Varun Kohli on 3/20/22.
//

import Foundation
import Web3
import PromiseKit

class FriendsFeedViewModel : ObservableObject {
  
  @Published var recentEvents: [FriendsFeedFetcher.NFTItem] = []
  var recentEventsPublished: Published<[FriendsFeedFetcher.NFTItem]> { _recentEvents }
  var recentEventsPublisher: Published<[FriendsFeedFetcher.NFTItem]>.Publisher { $recentEvents }
  
  @Published var isInitialized = false
  
  private var isLoading = false
  private var isLoadingLatest = false
  
  private var fetcher : Promise<[FriendsFeedFetcher]>
  
  init(from:[EthereumAddress]) {
    self.fetcher = web3.eth.blockNumber().map { fromBlock in
      [FriendsFeedFetcher(from: from,fromBlock:fromBlock.quantity )]
    }
  }
  
  init(from:EthereumAddress) {
    self.fetcher = web3.eth.blockNumber().map { fromBlock in
      [ FriendsFeedFetcher(from: [from],fromBlock:fromBlock.quantity ) ]
    }
  }
  
  init(to:EthereumAddress) {
    self.fetcher = web3.eth.blockNumber().map { fromBlock in
      [ FriendsFeedFetcher(to: [to],fromBlock:fromBlock.quantity ) ]
    }
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else {
      return
    }
    self.isLoading = true
    
    _ = self.fetcher
      .done { fetcher in
        print("Loading friend events")
        
        var pendingCount = 0
        
        fetcher.forEach {
          pendingCount = pendingCount + 1
          $0.getRecentEvents(
            onDone:{
              DispatchQueue.main.async {
                print("pendingCount",pendingCount)
                pendingCount = pendingCount - 1
                if (pendingCount <= 0) {
                  callback();
                  self.isLoading = false;
                  self.isInitialized = true
                  print("Done loading friend events")
                }
              }
            }) { nft in
              DispatchQueue.main.async {
                self.recentEvents.append(nft)
              }
            }
        }
      }
  }
  
  func getRecentEvents(currentIndex:Int?,_ callback : @escaping () -> Void) {
    guard let index = currentIndex else {
      loadMore(callback)
      return
    }
    let thresholdIndex = self.recentEvents.index(self.recentEvents.endIndex, offsetBy: -5)
    // print("getRecentEvents",thresholdIndex,index)
    if index >= thresholdIndex {
      loadMore(callback)
    } else {
      callback()
    }
  }
  
  func loadLatest(_ callback : @escaping () -> Void) {
    guard !isLoadingLatest else {
      return
    }
    self.isLoadingLatest = true;
    _ = self.fetcher
      .done { fetcher in
        
        var pendingCount = 0
        
        fetcher.forEach {
          pendingCount = pendingCount + 1
          $0.refreshLatestEvents(
            onDone:{
              DispatchQueue.main.async {
                pendingCount = pendingCount - 1
                if (pendingCount <= 0) {
                  self.isLoadingLatest = false;
                  callback();
                }
              }
            }) { nft in
              DispatchQueue.main.async {
                self.recentEvents.insert(nft,at:0)
              }
            }
        }
        
      }
  }
  
}
