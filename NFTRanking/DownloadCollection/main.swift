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
let result = ENSWrapper(eth: web3.eth).textAddrOfName(namehash: namehash, key: "avatar")

let res = try(hang(result))
print(res)
