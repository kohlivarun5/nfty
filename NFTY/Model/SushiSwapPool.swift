//
//  SushiSwapPool.swift
//  NFTY
//
//  Created by Varun Kohli on 1/2/22.
//

import Foundation
import BigInt
import PromiseKit
import Web3
import Web3ContractABI


class SushiSwapPool : EthereumContract {
  
  let eth = web3.eth
  let events : [SolidityEvent] = []
  var address: EthereumAddress?
  
  init(address:String) {
    self.address = EthereumAddress(hexString: address)
  }
  
  struct Reserves {
    let reserve0 : BigUInt
    let reserve1 : BigUInt
  }
  
  private func getReserves() -> Promise<Reserves> {
    let inputs : [SolidityFunctionParameter] = []
    let outputs = [
      SolidityFunctionParameter(name: "reserve0", type: .uint256),
      SolidityFunctionParameter(name: "reserve1", type: .uint256),
      SolidityFunctionParameter(name: "blockTimestampLast", type: .uint32),
    ]
    let method = SolidityConstantFunction(name: "getReserves", inputs: inputs, outputs: outputs, handler: self)
    print("calling getReserves")
    return method.invoke(address!).call()
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
        return Reserves(reserve0: outputs["reserve0"] as! BigUInt, reserve1: outputs["reserve1"] as! BigUInt)
      }
  }
  
  func priceInEth() -> Promise<Double?> {
    return getReserves() .map { Double($0.reserve1) / Double($0.reserve0) }
  }
  
}
