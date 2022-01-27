//
//  NearNFT.swift
//  NFTY
//
//  Created by Varun Kohli on 1/26/22.
//

import Foundation
import PromiseKit
import BigInt

struct NearNFT {
  
  let account_id:String
  
  struct NFTContractMetadata : Decodable {
    let spec : String
    let name : String
    let symbol : String
    let icon: String?
    let base_uri: String?
    let reference: String?
    let reference_hash: String?
  }
  
  func nft_metadata() -> Promise<NFTContractMetadata> {
    return NearApi.call_function(
      account_id: account_id,
      method_name: "nft_metadata",
      args: Unit()
    )
  }
  
  struct Metadata : Decodable {
    let title : String?
    let description: String?
    let media: String?
    let media_hash: String?
    let copies: String?
    let issued_at: String?
    let expires_at: String?
    let starts_at: String?
    let updated_at: String?
    let extra: String?
    let reference: String?
    let reference_hash: String?
  }
  
  struct Token : Decodable {
    let token_id: String
    let owner_id: String
    let metadata: Metadata
  }
  
  private struct Unit : Encodable {}
  
  func nft_total_supply() -> Promise<String> {
    
    return NearApi.call_function(
      account_id: account_id,
      method_name: "nft_total_supply",
      args: Unit()
    )
  }
  
  func nft_token(token_id:BigUInt) -> Promise<Token?> {
    struct Input :Encodable {
      let token_id : String
    }
    
    return NearApi.call_function(
      account_id: account_id,
      method_name: "nft_token",
      args: Input(token_id: String(token_id))
    )
  }
  
}
