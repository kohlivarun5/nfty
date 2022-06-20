//
//  NearNFTContract.swift
//  NFTY
//
//  Created by Varun Kohli on 1/27/22.
//

import Foundation
import BigInt
import PromiseKit
import Cache
import UIKit
import Web3

class NearNFTContract : ContractInterface {
  
  var contractAddressHex: String
  var account_id : String
  let name : String
  let nearContract : NearNFT
  
  private var imageCache : DiskStorage<BigUInt,UIImage>
  private var imageCacheHD : DiskStorage<BigUInt,UIImage>
  
  struct RecentEventsPager {
    var offset : UInt = 0
    let limit : UInt = 20
  }
  private var recentEventsPager : RecentEventsPager
  
  init(name:String,account_id:String) {
    self.name = name
    self.account_id = account_id
    self.nearContract = NearNFT(account_id: account_id)
    self.contractAddressHex = account_id
    self.imageCache = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(contractAddressHex).ImageCache",expiry: .never),
      transformer: TransformerFactory.forImage())
    self.imageCacheHD = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(contractAddressHex).ImageCacheHD",expiry: .never),
      transformer: TransformerFactory.forImage())
    
    self.recentEventsPager = RecentEventsPager()
  }
  
  func getRecentTrades(onDone: @escaping () -> Void, _ response: @escaping (NFTWithPrice) -> Void) {
    let type = TradeEventType.bought
    ParasApi.activities(contract_id: self.account_id, token_id: nil, eventType:type, offset: recentEventsPager.offset,limit:recentEventsPager.limit)
      .map { result in
        result.data.results.map { result in
          
          guard let price = result.price?.numberDecimal else { return }
          guard let tokenId = BigUInt(result.token_id) else { return }
          
          response(
            NFTWithPrice(
              nft: self.getNFT(tokenId),
              blockNumber:.near(EthereumQuantity(quantity: BigUInt(result.msg.block_height))),
              indicativePrice: TokenPriceType.eager(
                NFTPriceInfo(
                  near: BigUInt(price),
                  blockNumber:EthereumQuantity(quantity: BigUInt(result.msg.block_height)),
                  type:type)))
          )
        }
      }
      .catch { print($0) }
      .finally(on:.main) {
        self.recentEventsPager.offset = self.recentEventsPager.offset + self.recentEventsPager.limit
        onDone()
      }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void, _ response: @escaping (NFTWithPrice) -> Void) {
    onDone()
  }
  
  private static func imageOfData(_ data:Data?) -> Media.IpfsImage? {
    return data
      .flatMap {
        UIImage(data:$0)
          .flatMap { image_hd in
            image_hd
              .jpegData(compressionQuality: 0.1)
              .flatMap { UIImage(data:$0) }
              .map { Media.IpfsImage(image:$0,image_hd:image_hd) }
          }
      }
  }
  
  private func fetchImage(_ tokenId:BigUInt) -> Promise<Data?> {
    return self.nearContract.nft_metadata()
      .then { metadata in
        self.nearContract.nft_token(token_id: tokenId)
          .map { token in (metadata,token) }
      }
      .then(on: DispatchQueue.global(qos:.userInitiated)) { (metadata,token) -> Promise<Data?> in
        
        let uri = metadata.base_uri.flatMap { baseUri in
          token.metadata.media.map { media in "\(baseUri)/\(media)" }
        }
        
        return Promise { seal in
          switch(
            uri
              .map(ipfsUrl)
              .flatMap { return URL(string:$0) }
            ,token.metadata.media.flatMap { $0.hasPrefix("http") || $0.hasPrefix("ipfs") ? $0 : nil}.flatMap { URL(string:$0) }) {
          case (.none,.none):
            // print(uri as Any,metadata,token)
            seal.reject(NSError(domain:"", code:404, userInfo:nil))
          case (_,.some(let url)),(.some(let url),_):
            var request = URLRequest(url:url)
            request.httpMethod = url.host.map { $0 == "ipfs.infura.io" ? "POST" : "GET"} ?? "GET"
            
            ImageLoadingSemaphore.wait()
            
            print("calling \(request.url!)")
            URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
              // print(data,response,error)
              ImageLoadingSemaphore.signal()
              seal.fulfill(data)
            }).resume()
          }
        }
      }
  }
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    return ObservablePromise(promise: Promise { seal in
      DispatchQueue.global(qos:.userInteractive).async {
        switch(try? self.imageCache.object(forKey:tokenId),try? self.imageCacheHD.object(forKey:tokenId)) {
        case (.some(let image),.some(let image_hd)):
          seal.fulfill(Media.IpfsImage(image: image,image_hd: image_hd))
        case (.none,_),(_,.none):
          self.fetchImage(tokenId)
            .done(on:DispatchQueue.global(qos: .background)) {
              let image = NearNFTContract.imageOfData($0)
              image.flatMap {
                try? self.imageCache.setObject($0.image, forKey: tokenId)
                try? self.imageCacheHD.setObject($0.image_hd, forKey: tokenId)
              }
              seal.fulfill(image)
            }
            .catch {
              print($0)
              seal.fulfill(nil)
            }
        }
      }
    })
  }
  
  func getNFT(_ tokenId: BigUInt) -> NFT {
    NFT(
      address: self.contractAddressHex,
      tokenId: tokenId,
      name: name,
      media: .ipfsImage(
        Media.IpfsImageLazy(
          tokenId:tokenId,
          download : self.download)
      )
    )
  }
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    NFTWithLazyPrice(nft: self.getNFT(BigUInt(tokenId)), getPrice: {
      ObservablePromise(
        promise:
          ParasApi.activities(contract_id: self.account_id, token_id: String(tokenId),eventType:nil,offset:nil,limit:nil)
          .map { (result:ParasApi.ActivitiesResult) in
            
            result.data.results
              .sorted {
                $0.msg.block_height > $1.msg.block_height
              }
              .first {
                switch(ParasApi.eventType($0.type)) {
                case .none:
                  return false
                case .some(.bought),.some(.minted):
                  return true
                case .some(.ask),.some(.bid),.some(.transfer):
                  return false
                }
              }
          }.map { (result:ParasApi.ActivitiesResult.Data.Result?) -> NFTPriceStatus in
            switch(result) {
            case .none:
              return NFTPriceStatus.unavailable
            case .some(let result):
              return NFTPriceStatus.known(
                NFTPriceInfo(
                  near: result.price.flatMap { BigUInt($0.numberDecimal) },
                  blockNumber:EthereumQuantity(quantity: BigUInt(result.msg.block_height)),
                  type:ParasApi.eventType(result.type)!))
            }
          }
      )
    })
  }
  
  func ownerOf(_ tokenId: BigUInt) -> Promise<UserAccount?> {
    return self.nearContract.nft_token(token_id: tokenId)
      .map { UserAccount(ethAddress:nil, nearAccount:$0.owner_id) }
  }
  
  func getOwnerTokens(address: EthereumAddress, onDone: @escaping () -> Void, _ response: @escaping (NFTWithLazyPrice) -> Void) {
    /*
     self.nearContract.nft_tokens_for_owner(owner_account_id: address, from_index: nil, limit: nil)
     .map { tokens in
     tokens.forEach {
     guard let token_id = UInt($0.token_id) else { return }
     response(getToken(token_id))
     }
     }
     .catch { print($0) }
     .finally { onDone() }
     */
    onDone()
  }
  
  func getEventsFetcher(_ tokenId: BigUInt) -> TokenEventsFetcher? {
    
    struct ParasEventsFetcher : TokenEventsFetcher {
      
      let contract_id : String
      let token_id : String
      
      func getEvents(onDone: @escaping () -> Void, _ response: @escaping (TradeEvent) -> Void) {
        ParasApi.activities(contract_id: self.contract_id, token_id: token_id,eventType:nil,offset:nil,limit:nil)
          .map { (result:ParasApi.ActivitiesResult) in
            
            result.data.results.map { result in
              guard let type = ParasApi.eventType(result.type) else { return }
              response(
                TradeEvent(
                  type: type,
                  value:  result.price.flatMap { BigUInt($0.numberDecimal) }.map { PriceUnit.near($0) } ?? PriceUnit.near(BigUInt(0)),
                  blockNumber: .near(EthereumQuantity(quantity: BigUInt(result.msg.block_height))))
              )
            }
            
          }
          .catch { print($0) }
          .finally { onDone() }
      }
      
    }
    
    return ParasEventsFetcher(contract_id: self.account_id, token_id: String(tokenId))
    
  }
  
  func indicativeFloor() -> Promise<PriceUnit?> {
    return ParasApi.collection_stats(collection_id: self.account_id)
      .map {
        guard let floor_price = BigUInt($0.data.results.floor_price) else { return nil }
        return PriceUnit.near(floor_price)
      }
  }
  
  var vaultContract: CollectionVaultContract? = nil
  
  struct TradeInterface : TokenTradeInterface {
    let contract_id : String
    
    private func getAsk(_ tokenId:BigUInt,_ side:Side?) -> Promise<AskInfo?> {
      switch(side) {
      case .some(.ask),.none:
        return ParasApi.token(contract_id: self.contract_id, token_id: String(tokenId))
          .map { (response:ParasApi.Token) -> AskInfo? in
            response.data.results
              .first
              .flatMap { $0.price }
              .flatMap { BigUInt($0) }.map { AskInfo(price:.near($0),expiration_time: nil) }
          }
      case .some(.bid):
        return Promise.value(nil)
      }
    }
    
    private func getBid(_ tokenId:BigUInt,_ side:Side?) -> Promise<BidInfo?> {
      switch(side) {
      case .some(.bid),.none:
        return ParasApi.offers(contract_id: self.contract_id, token_id: String(tokenId))
          .map { (response:ParasApi.Offers) -> BidInfo? in
            response.data.results
            .compactMap { $0.price }
            .compactMap { BigUInt($0) }
              .sorted { $0 > $1 }
              .first
              .map { BidInfo(price:.near($0),expiration_time: nil) }
          }
      case .some(.ask):
        return Promise.value(nil)
      }
    }
    
    func getBidAsk(_ tokenId:BigUInt,_ side:Side?) -> Promise<BidAsk> {
      let ask = self.getAsk(tokenId,side)
      let bid = self.getBid(tokenId,side)
      
      return bid.then { bid in
        ask.map { ask in
          BidAsk(bid:bid, ask:ask)
        }
      }
    }
    
    func getBidAsk(_ tokenIds: [BigUInt],_ side:Side) -> Promise<[(tokenId:BigUInt,bidAsk:BidAsk)]> {
      return getBidAskSerial(tokenIds: tokenIds,side,wait:0.005, getter: self.getBidAsk)
    }
    var actions : TradeActionsInterface? = nil
  }
  
  lazy var tradeActions: TokenTradeInterface? = {
    return TradeInterface(contract_id: self.account_id)
  }()
  
  class FloorFetcher : PagedTokensFetcher {
    
    let contract : NearNFTContract
    var offset : UInt
    let limit : UInt
    
    init(contract:NearNFTContract) {
      self.contract = contract
      self.offset = 0
      self.limit = 20
    }
    
    func fetchNext() -> Promise<[NFTWithLazyPrice]> {
      ParasApi.token_series(collection_id: self.contract.account_id, offset: self.offset, limit: self.limit, sort: ParasApi.Sort.lowest_price)
        .map { result in
          self.offset = self.offset + self.limit
          
          return result.data.results.compactMap { result -> NFTWithLazyPrice? in
            guard let tokenId = BigUInt(result.token_series_id) else { return nil }
            guard let price = (result.lowest_price.flatMap { BigUInt($0) }) else { return nil }
            
            return NFTWithLazyPrice(
              nft: self.contract.getNFT(tokenId),
              getPrice: {
                ObservablePromise<NFTPriceStatus>(
                  resolved: NFTPriceStatus.known(
                    NFTPriceInfo(
                      near: price,
                      date:nil,
                      type:TradeEventType.ask)
                  )
                )
              }
            )
          }
        }
    }
    
  }
  
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? { return FloorFetcher(contract:self) }
  
}

func NearCollection(address:String) -> Collection {
  
  return Collection(
    info: CollectionInfo(
      address: address,
      sample: "SAMPLE_ASAC",
      name: address,
      webLink: nil,
      themeColor: .gunmetal,
      themeLabelColor: .white,
      disableRecentTrades: true,
      similarTokens: nil,
      rarityRanking: nil),
    contract: NearNFTContract(name: address, account_id: address)
  )
}

