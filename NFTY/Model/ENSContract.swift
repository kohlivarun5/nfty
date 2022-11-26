//
//  ENSContract.swift
//  NFTY
//
//  Created by Varun Kohli on 4/19/22.
//

// https://gist.github.com/hewigovens/9d078eb6b4e028ec78bce6abab71d980
import Foundation

// https://gist.github.com/kohlivarun5/a767680f91394eeec34588e96bed812c
import CryptoSwift
import Web3
import Web3ContractABI
import PromiseKit

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-137.md

// https://docs.ens.domains/contract-api-reference/reverseregistrar

// print(ENSContract.namehash("chilluminati.eth"))

// https://etherscan.io/address/0x00000000000c2e074ec69a0dfb2997ba6c7d2e1e#readContract
// -> resolver for namehash
// resolver : https://etherscan.io/address/0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41#readProxyContract
// -> add for namehash

// print(ENSContract.namehash("Ae71923d145ec0eAEDb2CF8197A08f12525Bddf4.addr.reverse".lowercased()))
// https://etherscan.io/address/0x00000000000c2e074ec69a0dfb2997ba6c7d2e1e#readContract
// -> resolver for namehash (lowercased address +++)
// resolver : https://etherscan.io/address/0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41#readProxyContract
// -> add for namehash
class ENSContract : EthereumContract {

  let address: EthereumAddress?
  let eth: Web3.Eth
  let events: [SolidityEvent] = []

  init(eth:Web3.Eth) {
    self.address = try? EthereumAddress(hex:"0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",eip55:true)
    self.eth = eth
  }

  static public func namehash(_ name:String) -> SolidityWrappedValue {
    var node = Array<UInt8>.init(repeating: 0x0, count: 32)
    if name.count > 0 {
      node = name.split(separator: ".")
        .map { Array($0.utf8).sha3(.keccak256) }
        .reversed()
        .reduce(node) { return ($0 + $1).sha3(.keccak256) }
    }
    return SolidityWrappedValue.fixedBytes(Data(node))
  }

  static private var resolverCache : [String:EthereumAddress?] = [:]

  public func resolver(namehash:SolidityWrappedValue) -> Promise<EthereumAddress?> {

    if let resolver = ENSContract.resolverCache[namehash.value.abiEncode(dynamic: false)!] { return Promise.value(resolver) }

    let inputs = [SolidityFunctionParameter(name: "node", type: .bytes(length: 32))]
    let outputs = [SolidityFunctionParameter(name: "address", type: .address)]
    let method = SolidityConstantFunction(name: "resolver", inputs: inputs, outputs: outputs, handler: self)
    print("calling ens resolver")
    return method.invoke(namehash.value).call()
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
        return outputs["address"] as? EthereumAddress
      }
      .map {
        ENSContract.resolverCache[namehash.value.abiEncode(dynamic: false)!] = $0
        return $0
      }
  }

  class AddrResolverContract : EthereumContract {

    let eth: Web3.Eth
    let events: [SolidityEvent] = []
    let address: EthereumAddress?

    init(address:EthereumAddress?,eth:Web3.Eth) {
      self.address = address
      self.eth = eth
    }

    func addr(namehash:SolidityWrappedValue) -> Promise<EthereumAddress?> {
      let inputs = [SolidityFunctionParameter(name: "input", type: .bytes(length: 32))]
      let outputs = [SolidityFunctionParameter(name: "addr", type: .address)]
      let method = SolidityConstantFunction(name: "addr", inputs: inputs, outputs: outputs, handler: self)
      print("calling ens resolver.addr")
      return method.invoke(namehash.value).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["addr"] as? EthereumAddress
        }
    }

    func text(namehash:SolidityWrappedValue,key:String) -> Promise<String?> {
      let inputs = [
        SolidityFunctionParameter(name: "node", type: .bytes(length: 32)),
        SolidityFunctionParameter(name: "key", type: .string)
      ]
      let outputs = [SolidityFunctionParameter(name: "value", type: .string)]
      let method = SolidityConstantFunction(name: "text", inputs: inputs, outputs: outputs, handler: self)
      print("calling ens resolver.text")
      return method.invoke(namehash.value,key).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["value"] as? String
        }
    }

    // function setText(bytes32 node, string calldata key, string calldata value) external authorised(node) {
    func setText(from:EthereumAddress,namehash:SolidityWrappedValue,key:String,value:String) -> EthereumTransaction {
      let inputs = [
        SolidityFunctionParameter(name: "node", type: .bytes(length: 32)),
        SolidityFunctionParameter(name: "key", type: .string),
        SolidityFunctionParameter(name: "value", type: .string),
      ]
      let method = SolidityPayableFunction(name: "setText", inputs: inputs, outputs: [], handler: self)

      return method.invoke(namehash.value,key,value).createTransaction(
        nonce: nil,
        gasPrice: nil,
        maxFeePerGas:nil,
        maxPriorityFeePerGas:nil,
        gasLimit: 200000,
        from: from,
        value:nil,
        accessList:[:],
        transactionType:.legacy)!
    }
  }

  class NameResolverContract : EthereumContract {

    let eth: Web3.Eth
    let events: [SolidityEvent] = []
    let address: EthereumAddress?

    init(address:EthereumAddress?,eth:Web3.Eth) {
      self.address = address
      self.eth = eth
    }

    func name(namehash:SolidityWrappedValue) -> Promise<String?> {
      let inputs = [SolidityFunctionParameter(name: "input", type: .bytes(length: 32))]
      let outputs = [SolidityFunctionParameter(name: "name", type: .string)]
      let method = SolidityConstantFunction(name: "name", inputs: inputs, outputs: outputs, handler: self)
      print("calling ens resolver.name")
      return method.invoke(namehash.value).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["name"] as? String
        }
    }
  }

  static private func nameToOwner(_ name:String,eth:Web3.Eth) -> Promise<EthereumAddress?> {
    let contract = ENSContract(eth: eth)
    let namehash = ENSContract.namehash(name)
    return contract.resolver(namehash:namehash)
      .then { (address:EthereumAddress?) -> Promise<EthereumAddress?> in
        let contract = AddrResolverContract(address:address, eth: eth);
        return contract.addr(namehash:namehash)
      }
  }

  static private func nameOfOwner(_ address:EthereumAddress,eth:Web3.Eth) -> Promise<String?> {
    let name = try! address.makeBytes().toHexString() + ".addr.reverse"
    let namehash = ENSContract.namehash(name.lowercased())
    let contract = ENSContract(eth: eth)
    return contract.resolver(namehash:namehash)
      .then { (address:EthereumAddress?) -> Promise<String?> in
        let contract = NameResolverContract(address: address, eth: eth)
        return contract.name(namehash:namehash)
      }
  }

  static private func avatarOwnerOfNamehash(_ nameHash:SolidityWrappedValue,eth:Web3.Eth) -> Promise<(EthereumAddress?,String?)> {
    let contract = ENSContract(eth: eth)
    return contract.resolver(namehash:nameHash)
      .then { (address:EthereumAddress?) -> Promise<(EthereumAddress?,String?)> in
        let contract = AddrResolverContract(address:address, eth: eth);
        return contract.text(namehash:nameHash,key:"avatar").then { avatar in
          return contract.addr(namehash:nameHash)
            .map { ($0,avatar) }
        }
      }
  }

  static private func avatarOfOwner(_ name:String,eth:Web3.Eth) -> Promise<String?> {
    let contract = ENSContract(eth: eth)
    let namehash = ENSContract.namehash(name)
    return contract.resolver(namehash:namehash)
      .then { (address:EthereumAddress?) -> Promise<String?> in
        let contract = AddrResolverContract(address:address, eth: eth);
        return contract.text(namehash:namehash,key:"avatar")
      }
  }

  static func setAvatar(_ name:String,from:EthereumAddress,avatar:NFT,eth:Web3.Eth) -> Promise<EthereumTransaction> {

    let contract = ENSContract(eth: eth)
    let namehash = ENSContract.namehash(name)
    return contract.resolver(namehash:namehash)
      .map { (address:EthereumAddress?) -> EthereumTransaction in
        let contract = AddrResolverContract(address:address, eth: eth);
        // eip155:1/[NFT standard]:[contract address for NFT collection]/[token ID or the number it is in the collection]
        let avatarValue = "eip155:1/erc721:\(avatar.address)/\(avatar.tokenId)"
        print("Setting avatar = \(avatarValue)")
        return contract.setText(from:from,namehash:namehash,key:"avatar",value:avatarValue)
      }
  }
}

// 0x74D0A6358d96c3c24Ea0116D9B33Dfdd9912aEd8

class ENSWrapper : EthereumContract {

  static let shared = ENSWrapper(eth: web3.eth)

  let ensAddress : EthereumAddress
  let address: EthereumAddress?
  let eth: Web3.Eth
  let events: [SolidityEvent] = []

  init(eth:Web3.Eth) {
    self.ensAddress = try! EthereumAddress(hex:"0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",eip55:true)
    self.address = try? EthereumAddress(hex:"0x74D0A6358d96c3c24Ea0116D9B33Dfdd9912aEd8",eip55:true)
    self.eth = eth
  }

  // function textAddrOfName(address ensAddress,bytes32 node,string calldata key) public view returns (string memory,address) {
  public func textAddrOfName(namehash:SolidityWrappedValue,key:String,block:BigUInt?) -> Promise<(String,EthereumAddress?)> {
    let inputs = [
      SolidityFunctionParameter(name: "ensAddress", type: .address),
      SolidityFunctionParameter(name: "node", type: .bytes(length: 32)),
      SolidityFunctionParameter(name: "key", type: .string)
    ]
    let outputs = [
      SolidityFunctionParameter(name: "text", type: .string),
      SolidityFunctionParameter(name: "owner", type: .address),
    ]
    let method = SolidityConstantFunction(name: "textAddrOfName", inputs: inputs, outputs: outputs, handler: self)
    print("calling ENSWrapper.textAddrOfName")
    return method.invoke(self.ensAddress,namehash.value,key).call(block: block.map { .block($0) } ?? .latest)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs -> (String,EthereumAddress?) in
        let (text,owner) = (outputs["text"] as! String,outputs["owner"] as! EthereumAddress)
        print("textAddrOfName returned with \(key)=\(text),owner=\(owner.hex(eip55: true))")
        return (text,owner.hex(eip55: true) == ETH_ADDRESS ? nil : owner)
      }
  }

  //  function textOfName(address ensAddress,bytes32 node,string calldata key) public view returns (string memory) {
  public func textOfName(namehash:SolidityWrappedValue,key:String,block:BigUInt?) -> Promise<String> {
    let inputs = [
      SolidityFunctionParameter(name: "ensAddress", type: .address),
      SolidityFunctionParameter(name: "node", type: .bytes(length: 32)),
      SolidityFunctionParameter(name: "key", type: .string)
    ]
    let outputs = [
      SolidityFunctionParameter(name: "text", type: .string)
    ]
    let method = SolidityConstantFunction(name: "textOfName", inputs: inputs, outputs: outputs, handler: self)
    print("calling ENSWrapper.textAddrOfName")
    return method.invoke(self.ensAddress,namehash.value,key).call(block: block.map { .block($0) } ?? .latest)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
        let text = outputs["text"] as! String
        print("textOfName returned with \(key)=\(text)")
        return text
      }
  }


  // function nameOfAdr(address ensAddress,bytes32 node) public view returns (string memory) {
  private func nameOfAdr(namehash:SolidityWrappedValue) -> Promise<(String)> {
    let inputs = [
      SolidityFunctionParameter(name: "ensAddress", type: .address),
      SolidityFunctionParameter(name: "node", type: .bytes(length: 32)),
    ]
    let outputs = [
      SolidityFunctionParameter(name: "name", type: .string)
    ]
    let method = SolidityConstantFunction(name: "nameOfAdr", inputs: inputs, outputs: outputs, handler: self)
    print("calling ENSWrapper.nameOfAdr")
    return method.invoke(self.ensAddress,namehash.value).call()
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs -> String in
        let name = outputs["name"] as! String
        print("nameOfAdr returned with name=\(name)")
        return name
      }
  }

  // function addrOfName(address ensAddress,bytes32 node) public view returns (address) {
  private func addrOfName(namehash:SolidityWrappedValue) -> Promise<(EthereumAddress?)> {
    let inputs = [
      SolidityFunctionParameter(name: "ensAddress", type: .address),
      SolidityFunctionParameter(name: "node", type: .bytes(length: 32)),
    ]
    let outputs = [
      SolidityFunctionParameter(name: "address", type: .address)
    ]
    let method = SolidityConstantFunction(name: "addrOfName", inputs: inputs, outputs: outputs, handler: self)
    print("calling ENSWrapper.addrOfName")
    return method.invoke(self.ensAddress,namehash.value).call()
      .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs -> EthereumAddress? in
        let address = outputs["address"] as! EthereumAddress
        print("addrOfName returned with address=\(address)")
        return address.hex(eip55: true) == ETH_ADDRESS ? nil : address
      }
  }

  public func nameOfOwner(_ address:EthereumAddress,eth:Web3.Eth) -> Promise<String?> {
    let name = try! address.makeBytes().toHexString() + ".addr.reverse"
    let namehash = ENSContract.namehash(name.lowercased())
    return self.nameOfAdr(namehash: namehash).map { $0.isEmpty ? nil : $0 }
  }

  public func avatarOfOwner(_ name:String,eth:Web3.Eth) -> Promise<String?> {
    let namehash = ENSContract.namehash(name)
    return self.textOfName(namehash: namehash,key: "avatar",block:nil).map { $0.isEmpty ? nil : $0 }
  }

  public func nameToOwner(_ name:String,eth:Web3.Eth) -> Promise<EthereumAddress?> {
    let namehash = ENSContract.namehash(name)
    return self.addrOfName(namehash: namehash)
  }
}
