//
//  main.swift
//  DownloadCollection
//
//  Created by Varun Kohli on 7/21/21.
//

import Foundation
import PromiseKit
import BigInt
import Web3
import Web3ContractABI

let namehash = ENSContract.namehash("chilluminati.eth")
print("namehash",namehash.value.abiEncode(dynamic: false))
let result = ENSWrapper(eth: web3.eth).textAddrOfName(namehash: namehash, key: "avatar", block: nil)

let TextChanged: SolidityEvent = SolidityEvent(name: "TextChanged", anonymous: false, inputs: [
  SolidityEvent.Parameter(name: "node", type: .bytes(length: 32), indexed: true),
  SolidityEvent.Parameter(name: "indexedKey", type: .string, indexed: true),
  SolidityEvent.Parameter(name: "key", type: .string, indexed: false),
])

let logsFetcher = LogsFetcher(
  event: TextChanged,
  fromBlock: BigUInt(16051027),
  address: "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41",
  indexedTopics: [],
  blockDecrements: 5000)


logsFetcher.fetch(onDone: {
 print("onDOne")
},retries:100) { log in
    guard let removed = log.removed else { return }
    if (removed) { return }
    
    let res = try! web3.eth.abi.decodeLog(event:TextChanged,from:log);
    print(res)
}

sleep(100)
