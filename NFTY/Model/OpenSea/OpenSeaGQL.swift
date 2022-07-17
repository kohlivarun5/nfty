//
//  OpenSeaGQL.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import Foundation
import Web3
import PromiseKit


struct OpenSeaGQL {
  
  struct QueryResult : Decodable {
    
    struct SelectedCollections : Decodable {
      struct Edge : Decodable {
        struct Node : Decodable {
          let name : String
        }
        let node : Node
      }
      let edges : [Edge]
    }
    let selectedCollections : SelectedCollections
    
    struct Search : Decodable {
      struct Edge : Decodable {
        struct Node : Decodable {
          struct Asset : Decodable {
            struct AssetContract : Decodable {
              let address : String
            }
            let assetContract : AssetContract
            let collection : SelectedCollections.Edge.Node
            let tokenId : String
            
            struct OrderData : Decodable {
              struct Ask : Decodable {
                struct PaymentAssetQuantity : Decodable {
                  let quantity : String
                  struct Asset : Decodable {
                    let symbol : String
                  }
                  
                  let asset : Asset
                  let quantityInEth : String
                }
                let paymentAssetQuantity : PaymentAssetQuantity
              }
              let bestAsk : Ask?
            }
            let orderData : OrderData
          }
          
          let asset : Asset
          
        }
        let node : Node
      }
      let edges : [Edge]
      
      struct PageInfo : Decodable {
        let endCursor : String?
        let hasNextPage : Bool
      }
      let pageInfo : PageInfo
      let totalCount : UInt
    }
    
    let search : Search
  }
  
  enum HTTPError: Error {
    case unknown
    case error(status: Int, message: String?)
  }
  
  static func call(query:[String:Any]) -> Promise<QueryResult> {
    var request = URLRequest(url:URL(string:"https://api.opensea.io/graphql/")!)
    
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: query, options: [])
    
    // print(String(decoding:request.httpBody!,as:UTF8.self))
    
    request.setValue(
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Safari/605.1.15",
      forHTTPHeaderField:"User-Agent")
    
    request.setValue(
      "https://opensea.io/",
      forHTTPHeaderField:"referrer")
    
    request.setValue(
      "https://opensea.io",
      forHTTPHeaderField:"Origin")
    
    request.setValue(
      "api.opensea.io",
      forHTTPHeaderField:"Host")
    
    request.setValue(
      OpenSeaApiCore.API_KEY,
      forHTTPHeaderField:"X-API-KEY")
    
    request.setValue(
      "gc2dqISCvD13ZjzeXGbDX",
      forHTTPHeaderField:"X-BUILD-ID")
    
    request.setValue(
      "bd533b153dff5b775a0504f27a4ec5d3a13325045eaa720c797d1ea23a924c3e",
      forHTTPHeaderField:"x-signed-query")
    
    // X-API-KEY: 2f6f419a083c46de9d83ce3dbe7db601
    // X-BUILD-ID: gc2dqISCvD13ZjzeXGbDX
    // x-signed-query: bd533b153dff5b775a0504f27a4ec5d3a13325045eaa720c797d1ea23a924c3e
    
    return Promise.init { seal in
      
      OpenSeaApiCore.UrlSession.enqueue(with: request,completionHandler: { data, response, error in
        if let error = error { return seal.reject(error) }
        // print(String(decoding:data!,as:UTF8.self))
        
        struct Response : Decodable {
          struct ResponseData : Decodable {
            let query : QueryResult
          }
          
          let data : ResponseData
        }
        
        do {
          switch(try data.map { try JSONDecoder().decode(Response.self, from: $0) }?.data.query ) {
          case .some(let result):
            seal.fulfill(result)
            //seal.reject(HTTPError.unknown)
          case .none:
            if let httpResponse = response as? HTTPURLResponse {
              let error = HTTPError.error(status: httpResponse.statusCode,
                                          message: data.flatMap({ String(data: $0, encoding: .utf8) }))
              seal.reject(error)
            } else {
              seal.reject(HTTPError.unknown)
            }
          }
        } catch {
          print(String(decoding:data!,as:UTF8.self))
          seal.reject(error)
        }
      })
    }
  }
  
  static func assetSearchQuery(collection:String,cursor:String?,limit:UInt) -> [String:Any] {
    let variables : [String:Any?] = [
      "categories": nil,
      "chains": nil,
      "collection": collection,
      "collectionQuery": nil,
      "collectionSortBy": nil,
      "collections": [
        collection
      ],
      "count": limit,
      "cursor": cursor,
      "identity": nil,
      "includeHiddenCollections": nil,
      "numericTraits": nil,
      "paymentAssets": nil,
      "priceFilter": nil,//this.priceFilter.symbol ? this.priceFilter : null,
      "query": "",
      "resultModel": "ASSETS",
      "showContextMenu": true,
      "shouldShowQuantity": false,
      "sortAscending": true,
      "sortBy": "PRICE",
      "stringTraits": nil,
      "toggles": ["BUY_NOW"],
      "creator": nil,
      "assetOwner": nil,
      "isPrivate": nil,
      "safelistRequestStatuses": nil
    ]
    
    let searchQuery : [String:Any] = [
      "id": "AssetSearchQuery",
      "query": OpenSeaGQL.ASSET_SEARCH_QUERY,
      "variables": variables
    ]
    
    return searchQuery;
  }
  
  
  
  static let ASSET_SEARCH_QUERY = "query AssetSearchQuery(\n  $categories: [CollectionSlug!]\n  $chains: [ChainScalar!]\n  $collection: CollectionSlug\n  $collectionQuery: String\n  $collectionSortBy: CollectionSort\n  $collections: [CollectionSlug!]\n  $count: Int\n  $cursor: String\n  $identity: IdentityInputType\n  $includeHiddenCollections: Boolean\n  $numericTraits: [TraitRangeType!]\n  $paymentAssets: [PaymentAssetSymbol!]\n  $priceFilter: PriceFilterType\n  $query: String\n  $resultModel: SearchResultModel\n  $showContextMenu: Boolean = false\n  $shouldShowQuantity: Boolean = false\n  $sortAscending: Boolean\n  $sortBy: SearchSortBy\n  $stringTraits: [TraitInputType!]\n  $toggles: [SearchToggle!]\n  $creator: IdentityInputType\n  $assetOwner: IdentityInputType\n  $isPrivate: Boolean\n  $safelistRequestStatuses: [SafelistRequestStatus!]\n) {\n  query {\n    ...AssetSearch_data_2hBjZ1\n  }\n}\n\nfragment AssetCardAnnotations_assetBundle on AssetBundleType {\n  assetCount\n}\n\nfragment AssetCardAnnotations_asset_3Aax2O on AssetType {\n  assetContract {\n    chain\n    id\n  }\n  decimals\n  ownedQuantity(identity: $identity) @include(if: $shouldShowQuantity)\n  relayId\n  favoritesCount\n  isDelisted\n  isFavorite\n  isFrozen\n  hasUnlockableContent\n  ...AssetCardBuyNow_data\n  orderData {\n    bestAsk {\n      orderType\n      relayId\n      maker {\n        address\n      }\n    }\n  }\n  ...AssetContextMenu_data_3z4lq0 @include(if: $showContextMenu)\n}\n\nfragment AssetCardBuyNow_data on AssetType {\n  tokenId\n  relayId\n  assetContract {\n    address\n    chain\n    id\n  }\n  collection {\n    slug\n    id\n  }\n  orderData {\n    bestAsk {\n      relayId\n    }\n  }\n}\n\nfragment AssetCardContent_asset on AssetType {\n  relayId\n  name\n  ...AssetMedia_asset\n  assetContract {\n    address\n    chain\n    openseaVersion\n    id\n  }\n  tokenId\n  collection {\n    slug\n    id\n  }\n  isDelisted\n}\n\nfragment AssetCardContent_assetBundle on AssetBundleType {\n  assetQuantities(first: 18) {\n    edges {\n      node {\n        asset {\n          relayId\n          ...AssetMedia_asset\n          id\n        }\n        id\n      }\n    }\n  }\n}\n\nfragment AssetCardFooter_assetBundle on AssetBundleType {\n  ...AssetCardAnnotations_assetBundle\n  name\n  assetCount\n  assetQuantities(first: 18) {\n    edges {\n      node {\n        asset {\n          collection {\n            name\n            relayId\n            slug\n            isVerified\n            ...collection_url\n            id\n          }\n          id\n        }\n        id\n      }\n    }\n  }\n  assetEventData {\n    lastSale {\n      unitPriceQuantity {\n        ...AssetQuantity_data\n        id\n      }\n    }\n  }\n  orderData {\n    bestBid {\n      orderType\n      paymentAssetQuantity {\n        ...AssetQuantity_data\n        id\n      }\n    }\n    bestAsk {\n      maker {\n        address\n      }\n      closedAt\n      orderType\n      dutchAuctionFinalPrice\n      openedAt\n      priceFnEndedAt\n      quantity\n      decimals\n      paymentAssetQuantity {\n        quantity\n        ...AssetQuantity_data\n        id\n      }\n    }\n  }\n}\n\nfragment AssetCardFooter_asset_3Aax2O on AssetType {\n  ...AssetCardAnnotations_asset_3Aax2O\n  name\n  tokenId\n  collection {\n    slug\n    name\n    isVerified\n    ...collection_url\n    id\n  }\n  isDelisted\n  assetContract {\n    address\n    chain\n    openseaVersion\n    id\n  }\n  assetEventData {\n    lastSale {\n      unitPriceQuantity {\n        ...AssetQuantity_data\n        id\n      }\n    }\n  }\n  orderData {\n    bestBid {\n      orderType\n      paymentAssetQuantity {\n        ...AssetQuantity_data\n        id\n      }\n    }\n    bestAsk {\n      maker {\n        address\n      }\n      closedAt\n      orderType\n      dutchAuctionFinalPrice\n      openedAt\n      priceFnEndedAt\n      quantity\n      decimals\n      paymentAssetQuantity {\n        quantity\n        ...AssetQuantity_data\n        id\n      }\n    }\n  }\n}\n\nfragment AssetContextMenu_data_3z4lq0 on AssetType {\n  ...asset_edit_url\n  ...asset_url\n  ...itemEvents_data\n  relayId\n  isDelisted\n  isEditable {\n    value\n    reason\n  }\n  isListable\n  ownership(identity: {}) {\n    isPrivate\n    quantity\n  }\n  creator {\n    address\n    id\n  }\n  collection {\n    isAuthorizedEditor\n    id\n  }\n  imageUrl\n  ownedQuantity(identity: {})\n}\n\nfragment AssetMedia_asset on AssetType {\n  animationUrl\n  backgroundColor\n  collection {\n    displayData {\n      cardDisplayStyle\n    }\n    id\n  }\n  isDelisted\n  imageUrl\n  displayImageUrl\n}\n\nfragment AssetQuantity_data on AssetQuantityType {\n  asset {\n    ...Price_data\n    id\n  }\n  quantity\n}\n\nfragment AssetSearchFilter_data_3KTzFc on Query {\n  ...CollectionFilter_data_2qccfC\n  collection(collection: $collection) {\n    numericTraits {\n      key\n      value {\n        max\n        min\n      }\n      ...NumericTraitFilter_data\n    }\n    stringTraits {\n      key\n      ...StringTraitFilter_data\n    }\n    id\n  }\n  ...PaymentFilter_data_2YoIWt\n}\n\nfragment AssetSearchList_data_3Aax2O on SearchResultType {\n  asset {\n    assetContract {\n      address\n      chain\n      id\n    }\n    collection {\n      isVerified\n      relayId\n      id\n    }\n    relayId\n    tokenId\n    ...AssetSelectionItem_data\n    ...asset_url\n    id\n  }\n  assetBundle {\n    relayId\n    id\n  }\n  ...Asset_data_3Aax2O\n}\n\nfragment AssetSearch_data_2hBjZ1 on Query {\n  ...AssetSearchFilter_data_3KTzFc\n  ...SearchPills_data_2Kg4Sq\n  search(after: $cursor, chains: $chains, categories: $categories, collections: $collections, first: $count, identity: $identity, numericTraits: $numericTraits, paymentAssets: $paymentAssets, priceFilter: $priceFilter, querystring: $query, resultType: $resultModel, sortAscending: $sortAscending, sortBy: $sortBy, stringTraits: $stringTraits, toggles: $toggles, creator: $creator, isPrivate: $isPrivate, safelistRequestStatuses: $safelistRequestStatuses) {\n    edges {\n      node {\n        ...AssetSearchList_data_3Aax2O\n        __typename\n      }\n      cursor\n    }\n    totalCount\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment AssetSelectionItem_data on AssetType {\n  backgroundColor\n  collection {\n    displayData {\n      cardDisplayStyle\n    }\n    imageUrl\n    id\n  }\n  imageUrl\n  name\n  relayId\n}\n\nfragment Asset_data_3Aax2O on SearchResultType {\n  asset {\n    relayId\n    isDelisted\n    ...AssetCardContent_asset\n    ...AssetCardFooter_asset_3Aax2O\n    ...AssetMedia_asset\n    ...asset_url\n    ...itemEvents_data\n    orderData {\n      bestAsk {\n        paymentAssetQuantity {\n          quantityInEth\n          id\n        }\n      }\n    }\n    id\n  }\n  assetBundle {\n    relayId\n    ...bundle_url\n    ...AssetCardContent_assetBundle\n    ...AssetCardFooter_assetBundle\n    orderData {\n      bestAsk {\n        paymentAssetQuantity {\n          quantityInEth\n          id\n        }\n      }\n    }\n    id\n  }\n}\n\nfragment CollectionFilter_data_2qccfC on Query {\n  selectedCollections: collections(first: 25, collections: $collections, includeHidden: true) {\n    edges {\n      node {\n        assetCount\n        imageUrl\n        name\n        slug\n        isVerified\n        id\n      }\n    }\n  }\n  collections(assetOwner: $assetOwner, assetCreator: $creator, onlyPrivateAssets: $isPrivate, chains: $chains, first: 100, includeHidden: $includeHiddenCollections, parents: $categories, query: $collectionQuery, sortBy: $collectionSortBy) {\n    edges {\n      node {\n        assetCount\n        imageUrl\n        name\n        slug\n        isVerified\n        id\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment CollectionModalContent_data on CollectionType {\n  description\n  imageUrl\n  name\n  slug\n}\n\nfragment NumericTraitFilter_data on NumericTraitTypePair {\n  key\n  value {\n    max\n    min\n  }\n}\n\nfragment PaymentFilter_data_2YoIWt on Query {\n  paymentAssets(first: 10) {\n    edges {\n      node {\n        symbol\n        relayId\n        id\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n  PaymentFilter_collection: collection(collection: $collection) {\n    paymentAssets {\n      symbol\n      relayId\n      id\n    }\n    id\n  }\n}\n\nfragment Price_data on AssetType {\n  decimals\n  imageUrl\n  symbol\n  usdSpotPrice\n  assetContract {\n    blockExplorerLink\n    chain\n    id\n  }\n}\n\nfragment SearchPills_data_2Kg4Sq on Query {\n  selectedCollections: collections(first: 25, collections: $collections, includeHidden: true) {\n    edges {\n      node {\n        imageUrl\n        name\n        slug\n        ...CollectionModalContent_data\n        id\n      }\n    }\n  }\n}\n\nfragment StringTraitFilter_data on StringTraitType {\n  counts {\n    count\n    value\n  }\n  key\n}\n\nfragment asset_edit_url on AssetType {\n  assetContract {\n    address\n    chain\n    id\n  }\n  tokenId\n  collection {\n    slug\n    id\n  }\n}\n\nfragment asset_url on AssetType {\n  assetContract {\n    address\n    chain\n    id\n  }\n  tokenId\n}\n\nfragment bundle_url on AssetBundleType {\n  slug\n}\n\nfragment collection_url on CollectionType {\n  slug\n}\n\nfragment itemEvents_data on AssetType {\n  assetContract {\n    address\n    chain\n    id\n  }\n  tokenId\n}\n"
}
