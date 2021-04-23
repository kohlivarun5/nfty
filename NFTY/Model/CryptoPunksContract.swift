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
  public var topics:[String]?
}

public struct EthereumLogData: Codable {
  public var blockNumber: EthereumQuantity
  public var data : String
  public var topics : [String]
}

extension Web3.Eth {
  public typealias Web3ResponseCompletion<Result: Codable> = (_ resp: Web3Response<Result>) -> Void
  public func getLogs(
    params: EthereumGetLogParams,
    response: @escaping Web3ResponseCompletion<[EthereumLogObject]>
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

var web3 = Web3(rpcURL: "https://mainnet.infura.io/v3/b4287cfd0a6b4849bd0ca79e144d3921")

struct CryptoPunksContract {
  
  private var PunkBought: SolidityEvent {
    let inputs: [SolidityEvent.Parameter] = [
      SolidityEvent.Parameter(name: "punkIndex", type: .uint256, indexed: true),
      SolidityEvent.Parameter(name: "value", type: .uint256, indexed: true),
      SolidityEvent.Parameter(name: "fromAddress", type: .address, indexed: true),
      SolidityEvent.Parameter(name: "toAddress", type: .address, indexed: true)
    ]
    return SolidityEvent(name: "PunkBought", anonymous: false, inputs: inputs)
  }
  
  
  private var contractAddress = try! EthereumAddress(hex: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb", eip55: false)
  private var contract = try! web3.eth.Contract(
    json:loadData("CryptoPunksAbi.json"),
    abiKey: nil,
    address: try! EthereumAddress(hex: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb", eip55: false))
  
  func getRecentTrades(response: @escaping (NFT) -> Void) {
    print("Called getRecentTrades");
    // Get balance of some address
    return web3.eth.getLogs(
      params:EthereumGetLogParams(
        fromBlock:.block(12290614),
        toBlock:.latest,
        address:contractAddress,
        topics: [
          web3.eth.abi.encodeEventSignature(self.PunkBought)
        ]
      )
    ) { result in
      if case let logs? = result.result {
        logs.map {
          do {
            let res = try web3.eth.abi.decodeLog(event:self.PunkBought,from:$0);
            print(res);
            response(NFT(
              address:"0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb",
              tokenId:String(res["punkIndex"] as! BigUInt),
              name:"CryptoPunks",
              url:URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk\(String(format: "%04d", Int(res["punkIndex"] as! BigUInt))).png")!,
              eth:Double(res["value"] as! BigUInt) / 1000000000000000000 / 1000000000000000000 / 1000000000000 // TODO
            ))
          } catch {
            print("Unexpected error: \(error).")
          }
        }
      }
    }
  }
}
