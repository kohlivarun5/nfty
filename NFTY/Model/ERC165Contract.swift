//
//  ERC165Contract.swift
//  NFTY
//
//  Created by Varun Kohli on 3/21/22.
//

import Foundation
import Web3
import Web3ContractABI
import PromiseKit
import Web3PromiseKit

class ERC165Contract : EthereumContract {
  
  let eth = web3.eth
  let events : [SolidityEvent] = []
  let address : EthereumAddress?
  
  init(address : EthereumAddress) {
    self.address = address
  }
  
  func supportsInterface(interfaceId:String) -> Promise<Bool> {
    let inputs = [SolidityFunctionParameter(name: "interfaceID", type: .bytes(length: 4))]
    let outputs = [SolidityFunctionParameter(name: "isSupport", type: .bool)]
    let method = SolidityConstantFunction(name: "supportsInterface", inputs: inputs, outputs: outputs, handler: self)
    print("calling supportsInterface")
    return method.invoke(interfaceId).call()
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
        print(outputs)
        return (outputs["supportsInterface"] as? Bool) ?? false
      }
  }
}
