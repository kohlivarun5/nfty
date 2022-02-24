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
import Cache


class SushiSwapPool : EthereumContract {
  
  let eth = web3.eth
  let events : [SolidityEvent] = []
  var address: EthereumAddress?
  
  private let cache = try! DiskStorage<String, Reserves>(
    config: DiskConfig(name: "SushiSwapPool.getReserves",expiry: .seconds(30)),
    transformer: TransformerFactory.forCodable(ofType: Reserves.self))
  
  init(address:String) {
    self.address = EthereumAddress(hexString: address)
  }
  
  struct Reserves : Codable {
    let reserve0 : BigUInt
    let reserve1 : BigUInt
  }
  
  private func getReservesImpl() -> Promise<Reserves> {
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
  
  private func getReserves() -> Promise<Reserves> {
    try? cache.removeExpiredObjects()
    
    switch(try? cache.object(forKey:self.address!.hex(eip55: true))) {
    case .some(let reserves):
      return Promise.value(reserves)
    case .none:
      return self.getReservesImpl()
        .map { reserves -> Reserves in
          try! self.cache.setObject(reserves,forKey:self.address!.hex(eip55: true));
          return reserves
        }
    }
  }
  
  func priceInEth() -> Promise<PriceUnit?> {
    return getReserves() .map { .wei( BigUInt(Double(1e18) * Double($0.reserve1) / Double($0.reserve0))) }
  }
  
  func priceInEthRev() -> Promise<PriceUnit?> {
    return getReserves() .map { .wei( BigUInt(Double(1e18) * Double($0.reserve0) / Double($0.reserve1))) }
  }
  
}
