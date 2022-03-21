//
//  FriendsFeedViewModel.swift
//  NFTY
//
//  Created by Varun Kohli on 3/20/22.
//

import Foundation
import Web3

class FriendsFeedViewModel : ObservableObject {
  
  @Published var recentEvents: [FriendsFeedFetcher.NFTItem] = []
  var recentEventsPublished: Published<[FriendsFeedFetcher.NFTItem]> { _recentEvents }
  var recentEventsPublisher: Published<[FriendsFeedFetcher.NFTItem]>.Publisher { $recentEvents }
  
  private var isLoading = false
  private var isLoadingLatest = false
  
  private var fetcher : FriendsFeedFetcher
  
  init(addresses:[EthereumAddress]) {
    self.fetcher = FriendsFeedFetcher(addresses: addresses)
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else {
      return
    }
    self.isLoading = true
    fetcher.getRecentEvents(
      onDone:{
        self.isLoading = false;
        callback();
      }) { nft in
        DispatchQueue.main.async {
          self.recentEvents.append(nft)
        }
      }
  }
  
  func getRecentEvents(currentIndex:Int?,_ callback : @escaping () -> Void) {
    guard let index = currentIndex else {
      loadMore(callback)
      return
    }
    let thresholdIndex = self.recentEvents.index(self.recentEvents.endIndex, offsetBy: -5)
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
    fetcher.refreshLatestEvents(
      onDone:{
        self.isLoadingLatest = false;
        callback();
      }) { nft in
        DispatchQueue.main.async {
          self.recentEvents.insert(nft,at:0)
        }
      }
  }
  
}
