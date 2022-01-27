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
  
  struct Token : Decodable {
    let id: String
    let owner_id: String
  }
  
  private struct Unit : Encodable {}
  
  func nft_total_supply() -> Promise<String> {
    
    return NearApi.call_function(
      account_id: account_id,
      method_name: "nft_total_supply",
      args: Unit()
    )
  }
  
  func nft_token(token_id:String) -> Promise<Token> {
    struct Input :Encodable {
      let token_id : String
    }
    
    return NearApi.call_function(
      account_id: account_id,
      method_name: "nft_token",
      args: Input(token_id: token_id)
    )
  }
  
}
