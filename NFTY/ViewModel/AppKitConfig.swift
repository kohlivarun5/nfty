import Foundation
import ReownAppKit
import Web3
import CryptoSwift
import WalletConnectSigner

struct DefaultCryptoProvider: CryptoProvider {
  
  public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
    let publicKey = try EthereumPublicKey(
      message: message.bytes,
      v: EthereumQuantity(quantity: BigUInt(signature.v)),
      r: EthereumQuantity(signature.r),
      s: EthereumQuantity(signature.s)
    )
    return Data(publicKey.rawPublicKey)
  }
  
  public func keccak256(_ data: Data) -> Data {
    let digest = SHA3(variant: .keccak256)
    let hash = digest.calculate(for: [UInt8](data))
    return Data(hash)
  }
  
}


struct AppKitConfig {
    static func configure() {
        let metadata = AppMetadata(
            name: "NFTYgo",
            description: "NFTYgo",
            url: "www.nftygo.com",
            icons: ["https://nftygo.com/images/favicons/favicon.ico"],
            redirect: try! AppMetadata.Redirect(
                native: "nftygo://",
                universal: "https://nftygo.com/wc",
                linkMode: true
            )
        )
        
        let authParams = try! AuthRequestParams(
            domain: "nftygo.com",
            chains: ["eip155:1"], // Add other chains as needed
            nonce: UUID().uuidString,
            uri: "https://nftygo.com/login",
            nbf:nil,
            exp:nil,
            statement: "Sign in to NFTYgo",
            requestId: nil,
            resources: nil,
            
            methods: ["personal_sign", "eth_sendTransaction"]
        )
        
        AppKit.configure(
            projectId: "9d5192c30c18cef1fdd4b75fb57455f5", // Replace with your project ID
            metadata: metadata,
            crypto: DefaultCryptoProvider(),
            authRequestParams: authParams,
            recommendedWalletIds: ["c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96", // MetaMask
                                 "0b415a746fb9ee99def9c8a0c529120389d03b6d1266ba407be5d24b3b832078"], // Rainbow
            excludedWalletIds: []
        )
    }
}
