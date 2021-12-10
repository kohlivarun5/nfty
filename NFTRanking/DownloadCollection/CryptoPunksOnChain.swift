//
//  CryptoPunksOnChain.swift
//  DownloadCollection
//
//  Created by Varun Kohli on 12/10/21.
//

import Foundation

import Web3
import Web3PromiseKit
import Web3ContractABI

class CryptoPunksOnChain : EthereumContract {
  internal let address = try? EthereumAddress(hex:"0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2", eip55: false)
  
  let eth: Web3.Eth
  
  init(web3:Web3) { eth = web3.eth }
  
  var events: [SolidityEvent] = []
  
  // punkAttributes(uint16 index) external view returns (string memory text) {
  func punkAttributes(_ index:BigUInt) -> Promise<String> {
    let inputs = [SolidityFunctionParameter(name: "index", type: .uint16)]
    let outputs = [SolidityFunctionParameter(name: "text", type: .string)]
    let method = SolidityConstantFunction(name: "punkAttributes", inputs: inputs, outputs: outputs, handler: self)
    print("calling punkAttributes")
    return method.invoke(index).call()
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
        return outputs["text"] as! String
      }
  }
}
