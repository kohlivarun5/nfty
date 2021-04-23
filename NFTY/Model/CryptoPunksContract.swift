//
//  CryptoPunksContract.swift
//  NFTY
//
//  Created by Varun Kohli on 4/22/21.
//

import Foundation

import Web3
import Web3PromiseKit
import Web3ContractABI

public struct EthereumGetLogParams: Codable {
  public var fromBlock: EthereumQuantityTag?
  public var toBlock: EthereumQuantityTag?
  public var address: EthereumAddress?
}
   
extension Web3.Eth {
  public typealias Web3ResponseCompletion<Result: Codable> = (_ resp: Web3Response<Result>) -> Void
  public func getLogs(
    params: EthereumGetLogParams,
    response: @escaping Web3ResponseCompletion<EthereumData>
  ) {
    let req = RPCRequest<[EthereumGetLogParams]>(
      id: properties.rpcId,
      jsonrpc: Web3.jsonrpc,
      method: "eth_getLogs",
      params: [params]
    )
    
    properties.provider.send(request: req, response: response)
  }
}

var web3 = Web3(rpcURL: "https://mainnet.infura.io/b4287cfd0a6b4849bd0ca79e144d3921")

struct CryptoPunksContract {
  private var contractAddress = try! EthereumAddress(hex: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb", eip55: false)
  private var contract = try! web3.eth.Contract(
                                json:loadData("CryptoPunksAbi.json"),
                                abiKey: nil,
                                address: try! EthereumAddress(hex: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb", eip55: false))
  
  func getRecentTrades() {
    print("Called getRecentTrades");
    // Get balance of some address
    return web3.eth.getLogs(params:EthereumGetLogParams(fromBlock:.block(4984423),toBlock:.latest,address:contractAddress)) { result in
      print(result)
    }
    
  }
}
