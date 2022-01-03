//
//  CollectionVaultContract.swift
//  NFTY
//
//  Created by Varun Kohli on 1/3/22.
//

import Foundation
import BigInt
import PromiseKit
import Web3
import Web3ContractABI


class CollectionVaultContract : EthereumContract {
  
  let eth = web3.eth
  let events : [SolidityEvent] = []
  var address: EthereumAddress?
  
  init(address:String) {
    self.address = EthereumAddress(hexString: address)
  }
  
  func allHoldings() -> Promise<[BigUInt]> {
    let inputs : [SolidityFunctionParameter] = []
    let outputs = [
      SolidityFunctionParameter(name: "tokenIds", type: .array(type: .uint256, length: nil))
    ]
    let method = SolidityConstantFunction(name: "allHoldings", inputs: inputs, outputs: outputs, handler: self)
    print("calling allHoldings")
    return method.invoke(address!).call()
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
        return outputs["tokenIds"] as! [BigUInt]
      }
  }
  
}
