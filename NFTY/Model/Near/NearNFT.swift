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
  
  struct ContractMetadata : Decodable {
    let spec : String
    let name : String
    let symbol : String
    let icon: String?
    let base_uri: String?
    let reference: String?
    let reference_hash: String?
  }
  
  func nft_metadata() -> Promise<ContractMetadata> {
    
    // Add caching for this
    
    return NearApi.call_function(
      account_id: account_id,
      method_name: "nft_metadata",
      args: Unit()
    )
  }
  
  struct TokenMetadata : Decodable {
    let title : String?
    let description: String?
    let media: String?
    let media_hash: String?
    /*
    let copies: Int?
    let issued_at: Int?
    let expires_at: String?
    let starts_at: String?
    let updated_at: String?
    let extra: String?
    let reference: String?
    let reference_hash: String?
     */
  }
  
  struct Token : Decodable {
    let token_id: String
    let owner_id: String
    let metadata: TokenMetadata
  }
  
  private struct Unit : Encodable {}
  
  func nft_total_supply() -> Promise<String> {
    
    return NearApi.call_function(
      account_id: account_id,
      method_name: "nft_total_supply",
      args: Unit()
    )
  }
  
  enum NearNFTError : Error {
    case TokenNotFound
    case UnknownError
  }
  
  func nft_token(token_id:BigUInt) -> Promise<Token> {
    struct Input :Encodable {
      let token_id : String
    }
    
    let token_opt : Promise<Token?> = NearApi.call_function(
      account_id: account_id,
      method_name: "nft_token",
      args: Input(token_id: String(token_id))
    )
    
    return token_opt.then {
      $0.map { Promise.value($0) } ?? Promise.init(error: NearNFTError.TokenNotFound)
    }
  }
  
  func nft_supply_for_owner(owner_account_id:String) -> Promise<BigUInt?> {
    struct Input :Encodable {
      let account_id : String
    }
    
    let num_tokens : Promise<String?> = NearApi.call_function(
      account_id: self.account_id,
      method_name: "nft_supply_for_owner",
      args: Input(account_id:owner_account_id)
    )
    
    return num_tokens.then {
      $0.map { Promise.value(BigUInt($0)) } ?? Promise.init(error: NearNFTError.UnknownError)
    }
  }
  
  func nft_tokens_for_owner(owner_account_id:String,from_index:UInt?,limit:UInt?) -> Promise<[Token]> {
    struct Input : Encodable {
      let account_id : String
      let from_index: String?
      let limit: UInt?
    }
    
    let tokens : Promise<[Token]?> = NearApi.call_function(
      account_id: self.account_id,
      method_name: "nft_tokens_for_owner",
      args: Input(account_id:owner_account_id,from_index: from_index.map { String($0) },limit:limit)
    )
    
    return tokens.then {
      $0.map { Promise.value($0) } ?? Promise.init(error: NearNFTError.UnknownError)
    }
  }
  
}
