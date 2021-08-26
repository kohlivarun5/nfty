//
//  Web3Utils.swift
//  NFTY
//
//  Created by Varun Kohli on 8/24/21.
//

// https://github.com/gnosis/safe-ios/blob/b0372d0ef3c7fe0d595a02dd37c9745992f50bfb/Multisig/Logic/Models/PrivateKey/web3swift/SECP256K1.swift#L10
import Foundation
import Web3

struct Web3Utils {
  
  /// Hashes a personal message by first padding it with the "\u{19}Ethereum Signed Message:\n" string and message length string.
  /// Should be used if some arbitrary information should be hashed and signed to prevent signing an Ethereum transaction
  /// by accident.
  private static func hashPersonalMessage(_ personalMessage: Data) -> Data? {
    var prefix = "\u{19}Ethereum Signed Message:\n"
    prefix += String(personalMessage.count)
    guard let prefixData = prefix.data(using: .ascii) else {return nil}
    var data = Data()
    if personalMessage.count >= prefixData.count && prefixData == personalMessage[0 ..< prefixData.count] {
      data.append(personalMessage)
    } else {
      data.append(prefixData)
      data.append(personalMessage)
    }
    let hash = data.sha3(.keccak256)
    return hash
  }
  
  private static func publicToAddressData(_ publicKey: Data) -> Data? {
    if publicKey.count == 33 {
      guard let decompressedKey = SECP256K1.combineSerializedPublicKeys(keys: [publicKey], outputCompressed: false) else {return nil}
      return publicToAddressData(decompressedKey)
    }
    var stipped = publicKey
    if (stipped.count == 65) {
      if (stipped[0] != 4) {
        return nil
      }
      stipped = stipped[1...64]
    }
    if (stipped.count != 64) {
      return nil
    }
    let sha3 = stipped.sha3(.keccak256)
    let addressData = sha3[12...31]
    return addressData
  }
  
  private static func publicToAddress(_ publicKey: Data) -> EthereumAddress? {
    guard let addressData = Web3Utils.publicToAddressData(publicKey) else { return nil }
    let address = addressData.toHexString().addHexPrefix().lowercased()
    return try? EthereumAddress(hex:address,eip55: false)
  }
  
  private static func personalECRecover(_ personalMessage: Data, signature: Data) -> EthereumAddress? {
    if signature.count != 65 { return nil}
    let rData = signature[0..<32].bytes
    let sData = signature[32..<64].bytes
    var vData = signature[64]
    
    if vData >= 27 && vData <= 30 {
      vData -= 27
    } else if vData >= 31 && vData <= 34 {
      vData -= 31
    } else if vData >= 35 && vData <= 38 {
      vData -= 35
    }
    
    guard let signatureData = SECP256K1.marshalSignature(v: vData, r: rData, s: sData) else {return nil}
    guard let hash = Web3Utils.hashPersonalMessage(personalMessage) else {return nil}
    guard let publicKey = SECP256K1.recoverPublicKey(hash: hash, signature: signatureData) else {return nil}
    let addr =  Web3Utils.publicToAddress(publicKey)
    return addr
  }
  
  static func personalECRecover(_ personalMessage: String, signature: String) -> EthereumAddress? {
    let data = Data(personalMessage.utf8)
    guard let sig = Data.fromHex(signature) else { return nil }
    return Web3Utils.personalECRecover(data, signature:sig)
  }
  
}
