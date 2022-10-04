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
                  struct Asset : Decodable {
                    let symbol : String
                  }
                  
                  let asset : Asset
                  let quantity : String?
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
    
    request.setValue("opensea-web", forHTTPHeaderField: "x-app-id")
    
    request.setValue("8ed63f475c8d09dd6f8c87992e6969e86747ba537d24847c416ce3f69d1f73a6", forHTTPHeaderField: "x-signed-query")
    
    request.setValue(
      "5d3b962ef97e726c1f1c5db316afa143bf615556",
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
      "safelistRequestStatuses": nil,
      "prioritizeBuyNow": true,
    ]
    
    let searchQuery : [String:Any] = [
      "id": "AssetSearchQuery",
      "query": OpenSeaGQL.ASSET_SEARCH_QUERY,
      "variables": variables
    ]
    
    return searchQuery;
  }
  
  
  
  static let ASSET_SEARCH_QUERY = "query AssetSearchCollectionQuery(\n  $collection: CollectionSlug\n  $collections: [CollectionSlug!]\n  $count: Int\n  $cursor: String\n  $numericTraits: [TraitRangeType!]\n  $paymentAssets: [PaymentAssetSymbol!]\n  $priceFilter: PriceFilterType\n  $query: String\n  $resultModel: SearchResultModel\n  $showContextMenu: Boolean = false\n  $sortAscending: Boolean\n  $sortBy: SearchSortBy\n  $stringTraits: [TraitInputType!]\n  $toggles: [SearchToggle!]\n  $isAutoHidden: Boolean\n  $safelistRequestStatuses: [SafelistRequestStatus!]\n  $prioritizeBuyNow: Boolean = false\n  $rarityFilter: RarityFilterType\n) {\n  ...AssetSearchCollection_data_11pQ3o\n}\n\nfragment AssetAddToCartButton_order on OrderV2Type {\n  maker {\n    address\n    id\n  }\n  item {\n    __typename\n    ...itemEvents_data\n    ... on Node {\n      __isNode: __typename\n      id\n    }\n  }\n  ...ShoppingCartContextProvider_inline_order\n}\n\nfragment AssetCardBuyNow_data on AssetType {\n  tokenId\n  relayId\n  assetContract {\n    address\n    chain\n    id\n  }\n  orderData {\n    bestAskV2 {\n      relayId\n      priceType {\n        usd\n      }\n      id\n    }\n  }\n}\n\nfragment AssetContextMenu_data on AssetType {\n  ...asset_edit_url\n  ...asset_url\n  ...itemEvents_data\n  relayId\n  isDelisted\n  creator {\n    address\n    id\n  }\n  imageUrl\n}\n\nfragment AssetMediaAnimation_asset on AssetType {\n  ...AssetMediaImage_asset\n}\n\nfragment AssetMediaAudio_asset on AssetType {\n  backgroundColor\n  ...AssetMediaImage_asset\n}\n\nfragment AssetMediaContainer_asset_2V84VL on AssetType {\n  backgroundColor\n  ...AssetMediaEditions_asset_2V84VL\n}\n\nfragment AssetMediaEditions_asset_2V84VL on AssetType {\n  decimals\n}\n\nfragment AssetMediaImage_asset on AssetType {\n  backgroundColor\n  imageUrl\n  collection {\n    displayData {\n      cardDisplayStyle\n    }\n    id\n  }\n}\n\nfragment AssetMediaPlaceholderImage_asset on AssetType {\n  collection {\n    displayData {\n      cardDisplayStyle\n    }\n    id\n  }\n}\n\nfragment AssetMediaVideo_asset on AssetType {\n  backgroundColor\n  ...AssetMediaImage_asset\n}\n\nfragment AssetMediaWebgl_asset on AssetType {\n  backgroundColor\n  ...AssetMediaImage_asset\n}\n\nfragment AssetMedia_asset on AssetType {\n  animationUrl\n  displayImageUrl\n  imageUrl\n  isDelisted\n  ...AssetMediaAnimation_asset\n  ...AssetMediaAudio_asset\n  ...AssetMediaContainer_asset_2V84VL\n  ...AssetMediaImage_asset\n  ...AssetMediaPlaceholderImage_asset\n  ...AssetMediaVideo_asset\n  ...AssetMediaWebgl_asset\n}\n\nfragment AssetMedia_asset_2V84VL on AssetType {\n  animationUrl\n  displayImageUrl\n  imageUrl\n  isDelisted\n  ...AssetMediaAnimation_asset\n  ...AssetMediaAudio_asset\n  ...AssetMediaContainer_asset_2V84VL\n  ...AssetMediaImage_asset\n  ...AssetMediaPlaceholderImage_asset\n  ...AssetMediaVideo_asset\n  ...AssetMediaWebgl_asset\n}\n\nfragment AssetQuantity_data on AssetQuantityType {\n  asset {\n    ...Price_data\n    id\n  }\n  quantity\n}\n\nfragment AssetSearchCollection_data_11pQ3o on Query {\n  queriedAt\n  ...AssetSearchFilter_data_3KTzFc\n  ...PhoenixSearchPills_data_2Kg4Sq\n  search: collectionItems(after: $cursor, collections: $collections, first: $count, isAutoHidden: $isAutoHidden, numericTraits: $numericTraits, paymentAssets: $paymentAssets, resultType: $resultModel, priceFilter: $priceFilter, querystring: $query, safelistRequestStatuses: $safelistRequestStatuses, sortAscending: $sortAscending, sortBy: $sortBy, stringTraits: $stringTraits, toggles: $toggles, prioritizeBuyNow: $prioritizeBuyNow, rarityFilter: $rarityFilter) {\n    edges {\n      node {\n        __typename\n        relayId\n        ...AssetSearchList_data_27d9G3\n        ... on Node {\n          __isNode: __typename\n          id\n        }\n      }\n      cursor\n    }\n    totalCount\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment AssetSearchFilter_data_3KTzFc on Query {\n  collection(collection: $collection) {\n    numericTraits {\n      key\n      value {\n        max\n        min\n      }\n      ...NumericTraitFilter_data\n    }\n    stringTraits {\n      key\n      ...StringTraitFilter_data\n    }\n    defaultChain {\n      identifier\n    }\n    enabledRarities\n    ...RarityFilter_data\n    ...useIsRarityEnabled_collection\n    id\n  }\n  ...PaymentFilter_data_2YoIWt\n}\n\nfragment AssetSearchList_data_27d9G3 on ItemType {\n  __isItemType: __typename\n  __typename\n  relayId\n  ...ItemCard_data_1OrK6u\n  ... on AssetType {\n    collection {\n      isVerified\n      relayId\n      id\n    }\n    ...asset_url\n  }\n  ... on AssetBundleType {\n    bundleCollection: collection {\n      isVerified\n      relayId\n      id\n    }\n  }\n  chain {\n    identifier\n  }\n}\n\nfragment CollectionLink_assetContract on AssetContractType {\n  address\n  blockExplorerLink\n}\n\nfragment CollectionLink_collection on CollectionType {\n  name\n  slug\n  verificationStatus\n  ...collection_url\n}\n\nfragment ItemCardAnnotations_27d9G3 on ItemType {\n  __isItemType: __typename\n  relayId\n  __typename\n  ... on AssetType {\n    chain {\n      identifier\n    }\n    decimals\n    favoritesCount\n    isDelisted\n    isFrozen\n    hasUnlockableContent\n    ...AssetCardBuyNow_data\n    orderData {\n      bestAskV2 {\n        ...AssetAddToCartButton_order\n        orderType\n        maker {\n          address\n          id\n        }\n        id\n      }\n    }\n    ...AssetContextMenu_data @include(if: $showContextMenu)\n  }\n  ... on AssetBundleType {\n    assetCount\n  }\n}\n\nfragment ItemCardContent_2V84VL on ItemType {\n  __isItemType: __typename\n  __typename\n  ... on AssetType {\n    relayId\n    name\n    ...AssetMedia_asset_2V84VL\n  }\n  ... on AssetBundleType {\n    assetQuantities(first: 18) {\n      edges {\n        node {\n          asset {\n            relayId\n            ...AssetMedia_asset\n            id\n          }\n          id\n        }\n      }\n    }\n  }\n}\n\nfragment ItemCardFooter_27d9G3 on ItemType {\n  __isItemType: __typename\n  name\n  orderData {\n    bestBidV2 {\n      orderType\n      priceType {\n        unit\n      }\n      ...PriceContainer_data\n      id\n    }\n    bestAskV2 {\n      orderType\n      priceType {\n        unit\n      }\n      maker {\n        address\n        id\n      }\n      ...PriceContainer_data\n      id\n    }\n  }\n  ...ItemMetadata\n  ...ItemCardAnnotations_27d9G3\n  ... on AssetType {\n    tokenId\n    isDelisted\n    defaultRarityData {\n      ...RarityIndicator_data\n      id\n    }\n    collection {\n      slug\n      name\n      isVerified\n      ...collection_url\n      ...useIsRarityEnabled_collection\n      id\n    }\n  }\n  ... on AssetBundleType {\n    bundleCollection: collection {\n      slug\n      name\n      isVerified\n      ...collection_url\n      ...useIsRarityEnabled_collection\n      id\n    }\n  }\n}\n\nfragment ItemCard_data_1OrK6u on ItemType {\n  __isItemType: __typename\n  __typename\n  relayId\n  orderData {\n    bestAskV2 {\n      priceType {\n        eth\n      }\n      id\n    }\n  }\n  ...ItemCardContent_2V84VL\n  ...ItemCardFooter_27d9G3\n  ...item_url\n  ... on AssetType {\n    isDelisted\n    ...itemEvents_data\n  }\n}\n\nfragment ItemMetadata on ItemType {\n  __isItemType: __typename\n  __typename\n  orderData {\n    bestAskV2 {\n      closedAt\n      id\n    }\n  }\n  assetEventData {\n    lastSale {\n      unitPriceQuantity {\n        ...AssetQuantity_data\n        id\n      }\n    }\n  }\n}\n\nfragment NumericTraitFilter_data on NumericTraitTypePair {\n  key\n  value {\n    max\n    min\n  }\n}\n\nfragment OrderListItem_order on OrderV2Type {\n  relayId\n  item {\n    __typename\n    ... on AssetType {\n      __typename\n      displayName\n      assetContract {\n        ...CollectionLink_assetContract\n        id\n      }\n      collection {\n        slug\n        verificationStatus\n        ...CollectionLink_collection\n        id\n      }\n      ...AssetMedia_asset\n      ...asset_url\n      ...useAssetFees_asset\n    }\n    ... on AssetBundleType {\n      __typename\n    }\n    ...itemEvents_data\n    ... on Node {\n      __isNode: __typename\n      id\n    }\n  }\n  remainingQuantityType\n  ...OrderPrice\n}\n\nfragment OrderList_orders on OrderV2Type {\n  item {\n    __typename\n    relayId\n    ... on Node {\n      __isNode: __typename\n      id\n    }\n  }\n  relayId\n  ...OrderListItem_order\n}\n\nfragment OrderPrice on OrderV2Type {\n  priceType {\n    unit\n  }\n  perUnitPriceType {\n    unit\n  }\n  dutchAuctionFinalPriceType {\n    unit\n  }\n  openedAt\n  closedAt\n  payment {\n    ...TokenPricePayment\n    id\n  }\n}\n\nfragment PaymentFilter_data_2YoIWt on Query {\n  paymentAssets(first: 10) {\n    edges {\n      node {\n        symbol\n        id\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n  PaymentFilter_collection: collection(collection: $collection) {\n    paymentAssets {\n      symbol\n      id\n    }\n    id\n  }\n}\n\nfragment PhoenixSearchPills_data_2Kg4Sq on Query {\n  selectedCollections: collections(first: 25, collections: $collections, includeHidden: true) {\n    edges {\n      node {\n        imageUrl\n        name\n        slug\n        id\n      }\n    }\n  }\n}\n\nfragment PriceContainer_data on OrderV2Type {\n  ...OrderPrice\n}\n\nfragment Price_data on AssetType {\n  decimals\n  imageUrl\n  symbol\n  usdSpotPrice\n  assetContract {\n    blockExplorerLink\n    chain\n    id\n  }\n}\n\nfragment RarityFilter_data on CollectionType {\n  representativeRarityData {\n    maxRank\n    id\n  }\n}\n\nfragment RarityIndicator_data on RarityDataType {\n  rank\n  rankPercentile\n  rankCount\n  maxRank\n}\n\nfragment ShoppingCartContextProvider_inline_order on OrderV2Type {\n  relayId\n  item {\n    __typename\n    chain {\n      identifier\n    }\n    relayId\n    ... on Node {\n      __isNode: __typename\n      id\n    }\n  }\n  payment {\n    relayId\n    id\n  }\n  remainingQuantityType\n  ...ShoppingCart_orders\n}\n\nfragment ShoppingCartDetailedView_orders on OrderV2Type {\n  relayId\n  item {\n    __typename\n    chain {\n      identifier\n    }\n    ... on Node {\n      __isNode: __typename\n      id\n    }\n  }\n  supportsGiftingOnPurchase\n  ...useTotalPrice_orders\n  ...OrderList_orders\n}\n\nfragment ShoppingCartFooter_orders on OrderV2Type {\n  ...useTotalPrice_orders\n}\n\nfragment ShoppingCart_orders on OrderV2Type {\n  relayId\n  item {\n    __typename\n    relayId\n    chain {\n      identifier\n    }\n    ... on Node {\n      __isNode: __typename\n      id\n    }\n  }\n  payment {\n    relayId\n    symbol\n    id\n  }\n  ...ShoppingCartDetailedView_orders\n  ...ShoppingCartFooter_orders\n  ...useTotalPrice_orders\n}\n\nfragment StringTraitFilter_data on StringTraitType {\n  counts {\n    count\n    value\n  }\n  key\n}\n\nfragment TokenPricePayment on PaymentAssetType {\n  symbol\n  chain {\n    identifier\n  }\n  asset {\n    imageUrl\n    assetContract {\n      blockExplorerLink\n      id\n    }\n    id\n  }\n}\n\nfragment asset_edit_url on AssetType {\n  assetContract {\n    address\n    chain\n    id\n  }\n  tokenId\n  collection {\n    slug\n    id\n  }\n}\n\nfragment asset_url on AssetType {\n  assetContract {\n    address\n    id\n  }\n  tokenId\n  chain {\n    identifier\n  }\n}\n\nfragment bundle_url on AssetBundleType {\n  slug\n  chain {\n    identifier\n  }\n}\n\nfragment collection_url on CollectionType {\n  slug\n  isCategory\n}\n\nfragment itemEvents_data on AssetType {\n  relayId\n  assetContract {\n    address\n    id\n  }\n  tokenId\n  chain {\n    identifier\n  }\n}\n\nfragment item_url on ItemType {\n  __isItemType: __typename\n  __typename\n  ... on AssetType {\n    ...asset_url\n  }\n  ... on AssetBundleType {\n    ...bundle_url\n  }\n}\n\nfragment useAssetFees_asset on AssetType {\n  openseaSellerFeeBasisPoints\n  totalCreatorFee\n}\n\nfragment useIsRarityEnabled_collection on CollectionType {\n  slug\n  enabledRarities\n  isEligibleForRarity\n}\n\nfragment useTotalPrice_orders on OrderV2Type {\n  relayId\n  perUnitPriceType {\n    usd\n    unit\n  }\n  dutchAuctionFinalPriceType {\n    usd\n    unit\n  }\n  openedAt\n  closedAt\n  payment {\n    symbol\n    ...TokenPricePayment\n    id\n  }\n}\n"
}
