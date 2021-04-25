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

class CryptoPunksContract {
  
  private var PunkBought: SolidityEvent {
    let inputs: [SolidityEvent.Parameter] = [
      SolidityEvent.Parameter(name: "punkIndex", type: .uint256, indexed: true),
      SolidityEvent.Parameter(name: "value", type: .uint256, indexed: false),
      SolidityEvent.Parameter(name: "fromAddress", type: .address, indexed: true),
      SolidityEvent.Parameter(name: "toAddress", type: .address, indexed: true)
    ]
    return SolidityEvent(name: "PunkBought", anonymous: false, inputs: inputs)
  }
  
  private var name = "CryptoPunks"
  private var addressHex = "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb"
  private var fromBlock : BigUInt = 12290614
  private var blockDecrements : BigUInt = 10000
  private var toBlock = EthereumQuantityTag.latest
  
  func getRecentTrades(response: @escaping (NFT,Bool) -> Void) {
    // print("Called getRecentTrades");
    return web3.eth.getLogs(
      params:EthereumGetLogParams(
        fromBlock:.block(fromBlock),
        toBlock: toBlock,
        address:try! EthereumAddress(hex: addressHex, eip55: false),
        topics: [
          web3.eth.abi.encodeEventSignature(self.PunkBought)
        ]
      )
    ) { result in
      if case let logs? = result.result {
        self.toBlock = EthereumQuantityTag.block(self.fromBlock)
        self.fromBlock = self.fromBlock - self.blockDecrements
        logs.indices.forEach { index in
          let log = logs[index];
          let res = try! web3.eth.abi.decodeLog(event:self.PunkBought,from:log);
          response(NFT(
            address:self.addressHex,
            tokenId:String(res["punkIndex"] as! BigUInt),
            name:"CryptoPunks",
            url:URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk\(String(format: "%04d", Int(res["punkIndex"] as! BigUInt))).png")!,
            eth:Double(res["value"] as! BigUInt) / 1e18
          ),index == logs.count - 1)
        }
      }
    }
  }
}

class CryptoKittiesAuction {
  
  private var AuctionSuccessful: SolidityEvent {
    // event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    let inputs: [SolidityEvent.Parameter] = [
      SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: false),
      SolidityEvent.Parameter(name: "totalPrice", type: .uint256, indexed: false),
      SolidityEvent.Parameter(name: "winner", type: .address, indexed: true)
    ]
    return SolidityEvent(name: "AuctionSuccessful", anonymous: false, inputs: inputs)
  }
  
  struct Kitty: Codable {
    var image_url: String
  }
  
  private var name = "CryptoKitties"
  private var contractAddressHex = "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"
  private var saleAuctionContractAddress = try! EthereumAddress(hex: "0xb1690C08E213a35Ed9bAb7B318DE14420FB57d8C", eip55: false)
  private var fromBlock : BigUInt = 12290614
  private var blockDecrements : BigUInt = 10000
  private var toBlock = EthereumQuantityTag.latest
  
  private func getKitty(tokenId:BigUInt) -> Promise<Kitty> {
    return Promise { seal in
      var request = URLRequest(url: URL(string: "https://public.api.cryptokitties.co/v1/kitties/\(tokenId)")!)
      request.httpMethod = "GET"
      request.addValue("Uci2BC2E8vloA_Lmm43gGPXtXhvrSu6AYbac5GmTGy8",forHTTPHeaderField:"x-api-token")
      
      
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        do {
          let jsonDecoder = JSONDecoder()
          let kittyInfo = try jsonDecoder.decode(Kitty.self, from: data!)
          seal.fulfill(kittyInfo)
        } catch {
          print("JSON Serialization error")
        }
      }).resume()
    }
  }
  
  func getRecentTrades(response: @escaping (NFT,Bool) -> Void) {
    // print("Called getRecentTrades");
    return web3.eth.getLogs(
      params:EthereumGetLogParams(
        fromBlock:.block(fromBlock),
        toBlock:toBlock,
        address:saleAuctionContractAddress,
        topics: [
          web3.eth.abi.encodeEventSignature(self.AuctionSuccessful)
        ]
      )
    ) { result in
      if case let logs? = result.result {
        self.toBlock = EthereumQuantityTag.block(self.fromBlock)
        self.fromBlock = self.fromBlock - self.blockDecrements
        logs.indices.forEach { index in
          let log = logs[index];
          let res = try! web3.eth.abi.decodeLog(event:self.AuctionSuccessful,from:log);
          let tokenId = res["tokenId"] as! BigUInt;
          firstly {
            self.getKitty(tokenId:tokenId)
          }.done { kitty  in
            if (!kitty.image_url.hasSuffix(".svg")) {
              response(NFT(
                address:self.contractAddressHex,
                tokenId:String(tokenId),
                name:self.name,
                url:URL(string:kitty.image_url)!,
                eth:Double(res["totalPrice"] as! BigUInt) / 1e18
              ),index == logs.count - 1)
            }
          }
        }
      }
    }
  }
}
