//
//  ContractInterface.swift
//  NFTY
//
//  Created by Varun Kohli on 7/10/22.
//

import Foundation
import BigInt
import PromiseKit
import Web3

protocol ContractInterface {
  
  var contractAddressHex: String { get }
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void)
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void)
  
  func getNFT(_ tokenId:BigUInt) -> NFT
  func getToken(_ tokenId:UInt) -> NFTWithLazyPrice
  func ownerOf(_ tokenId:BigUInt) -> Promise<UserAccount?>
  func getOwnerTokens(address:EthereumAddress,onDone: @escaping () -> Void,_ response: @escaping (NFTWithLazyPrice) -> Void)
  
  func getEventsFetcher(_ tokenId:BigUInt) -> TokenEventsFetcher?
  
  func indicativeFloor() -> Promise<PriceUnit?>
  
  var vaultContract : CollectionVaultContract? { get }
  
  var tradeActions : TokenTradeInterface? { get }
  
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher?
  
}
