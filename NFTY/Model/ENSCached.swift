//
//  ENSCached.swift
//  NFTY
//
//  Created by Varun Kohli on 7/5/22.
//

import Foundation
import Web3
import Web3ContractABI
import Cache
import PromiseKit
import BigInt

struct ENSCached {
  
  struct Avatar : Codable {
    let owner : EthereumAddress?
    let avatar : String?
  }
  
  static let avatarCache = HybridStorage(
    memoryStorage: MemoryStorage<String, Avatar>(config: MemoryConfig()),
    diskStorage: try! DiskStorage<String, Avatar>(
      config: DiskConfig(name: "ENSCached.Avatar"),
      transformer:TransformerFactory.forCodable(ofType:Avatar.self))
  )
  
  static public func avatarOwnerOfNamehash(_ nameHash:SolidityWrappedValue,block:BigUInt?,eth:Web3.Eth) -> Promise<(EthereumAddress?,String?)> {
    return Promise { seal in
      DispatchQueue.global(qos: .userInitiated).async {
        switch(try? avatarCache.object(forKey:"\(nameHash.value.abiEncode(dynamic: false)!)@\(block ?? "")")) {
        case .some(let info):
          return seal.fulfill((info.owner,info.avatar))
        case .none:
          ENSWrapper.shared.textAddrOfName(namehash: nameHash, key: "avatar",block:block)
            .done {
              let (avatar,owner) = $0
              try? avatarCache.setObject(Avatar(owner: owner, avatar: avatar), forKey: "\(nameHash.value.abiEncode(dynamic: false)!)@\(block ?? "")")
              seal.fulfill((owner,avatar))
            }
            .catch { seal.reject($0) }
        }
      }
    }
  }
  
  struct NameOfOwner : Codable {
    let name : String?
  }
  
  static let nameOfOwnerCache = HybridStorage(
    memoryStorage: MemoryStorage<EthereumAddress, NameOfOwner>(config: MemoryConfig(expiry: Expiry.seconds(60))),
    diskStorage: try! DiskStorage<EthereumAddress, NameOfOwner>(
      config: DiskConfig(name: "ENSCached.NameOfOwner",expiry: Expiry.seconds(600)),
      transformer:TransformerFactory.forCodable(ofType:NameOfOwner.self))
  )
  
  
  static public func nameOfOwner(_ address:EthereumAddress,eth:Web3.Eth) -> Promise<String?> {
    return Promise { seal in
      DispatchQueue.global(qos: .userInitiated).async {
        try? nameOfOwnerCache.removeExpiredObjects()
        switch(try? nameOfOwnerCache.object(forKey:address)) {
        case .some(let info):
          return seal.fulfill(info.name)
        case .none:
          ENSWrapper.shared.nameOfOwner(address, eth: eth)
            .done {
              try? nameOfOwnerCache.setObject(NameOfOwner(name: $0), forKey: address)
              seal.fulfill($0)
            }
            .catch { seal.reject($0) }
        }
      }
    }
  }
  
}
