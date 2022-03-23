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
    let inputs = [SolidityFunctionParameter(name: "interfaceId", type: .bytes(length: 4))]
    let outputs = [SolidityFunctionParameter(name: "isSupport", type: .bool)]
    let method = SolidityConstantFunction(name: "supportsInterface", inputs: inputs, outputs: outputs, handler: self)
    print("calling supportsInterface for \(interfaceId). interface=\(method.signature)")
    
    return method.invoke(Data(hexString:interfaceId,length: 4)!).call()
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
        //print(outputs)
        return (outputs["isSupport"] as? Bool) ?? false
      }.recover { e-> Promise<Bool> in
        //print("Address=\(self.address?.hex(eip55: true) ?? "nil"),e=\(e)")
        return Promise.value(false)
      }
  }
}
