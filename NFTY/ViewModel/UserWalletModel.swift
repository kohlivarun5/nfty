//
//  UserWalletModel.swift
//  NFTY
//
//  Created by Varun Kohli on 7/31/21.
//

import Foundation
import Web3
import WalletConnectSwift
import PromiseKit

class UserWallet: ObservableObject {
  @Published var walletAddress : EthereumAddress?
  @Published var walletConnectSession : Session?
  
  init() {
    if let addr = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys
                                                            .walletAddress.rawValue) {
      self.walletAddress = try? EthereumAddress(hex:addr,eip55: false)
    } else {
      self.walletAddress = nil
    }
    
    if let oldSessionObject = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.walletConnect.rawValue) as? Data {
       self.walletConnectSession = try? JSONDecoder().decode(Session.self, from: oldSessionObject)
    }
    
  }
  
  func saveWalletAddress(address:EthereumAddress) {
    NSUbiquitousKeyValueStore.default.set(address.hex(eip55:true), forKey:CloudDefaultStorageKeys.walletAddress.rawValue)
    self.walletAddress = address
  }
  
  func saveWalletConnectSession(session:Session) {
    let sessionData = try! JSONEncoder().encode(session)
    NSUbiquitousKeyValueStore.default.set(sessionData, forKey: CloudDefaultStorageKeys.walletConnect.rawValue)
    DispatchQueue.main.async {
      self.walletConnectSession = session
    }
  }
  
  func removeWalletConnectSession() {
    NSUbiquitousKeyValueStore.default.removeObject(forKey: CloudDefaultStorageKeys.walletConnect.rawValue)
    self.walletConnectSession = nil
  }
  
  func connectToWallet(link: String) throws -> URL {
    let wcUrl = connect()
    let uri = wcUrl.fullyPercentEncodedStr
    var delimiter: String
    if link.contains("http") {
      delimiter = "/"
    } else {
      delimiter = "//"
    }
    let urlStr = "\(link)\(delimiter)wc?uri=\(uri)"
    return URL(string: urlStr)!
  }
  
  private func connect() -> WCURL {
    // gnosis wc bridge: https://safe-walletconnect.gnosis.io
    // test bridge with latest protocol version: https://bridge.walletconnect.org
    
    /*
     # For deep links
     examplewallet://wc?uri=wc:00e46b69-d0cc-4b3e-b6a2-cee442f97188@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=91303dedf64285cbbaf9120f6e9d160a5c8aa3deb67017a3874cd272323f48ae
     
     # For universal links
     https://https://metamask.app.link/wc?uri=wc:00e46b69-d0cc-4b3e-b6a2-cee442f97188@1?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=91303dedf64285cbbaf9120f6e9d160a5c8aa3deb67017a3874cd272323f48ae
     */
    
    // https://github.com/gnosis/safe-ios/blob/d4301687ce0a84e6bab2de398948d980deef3873/Multisig/Cross-layer/Configuration/Config.Example.xcconfig#L85
    let bridgeUrl = "https://safe-walletconnect.gnosis.io/" //https://wcbridge.zerion.io" //"https://bridge.walletconnect.org"
    
    let wcUrl =  WCURL(topic: UUID().uuidString,
                       bridgeURL: URL(string: bridgeUrl)!,
                       key: try! randomKey())
    let clientMeta = Session.ClientMeta(name: "NFTYgo",
                                        description: "NFTYgo",
                                        icons: [],
                                        url: URL(string: "www.nftygo.com")!)
    let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
    let client = Client(delegate: self, dAppInfo: dAppInfo)
    
    print("WalletConnect URL: \(wcUrl.absoluteString)")
    
    try! client.connect(to: wcUrl)
    return wcUrl
  }
  
  // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
  private func randomKey() throws -> String {
    var bytes = [Int8](repeating: 0, count: 32)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    if status == errSecSuccess {
      return Data(bytes: bytes, count: 32).toHexString()
    } else {
      // we don't care in the example app
      enum TestError: Error {
        case unknown
      }
      throw TestError.unknown
    }
  }
  
  struct WalletConnectProvider : WalletProvider {
    let account : EthereumAddress
    let client : Client
    let session : Session
    
    func sendTransaction(tx: EthereumTransaction) -> Promise<EthereumTransactionReceiptObject> {
      print("submitting")
      
      let transaction = Client.Transaction(
        from:tx.from!.hex(eip55: true),
        to:tx.to?.hex(eip55: true),
        data:tx.data.hex(),
        gas:tx.gas?.hex(),
        gasPrice:tx.gasPrice?.hex(),
        value:tx.value?.hex(),
        nonce: tx.nonce?.hex()
      )
      print(transaction)
      
      return Promise { seal in
        try? client.eth_sendTransaction(
          url: session.url,
          transaction: transaction)
        { res in
          print(res)
          seal.reject(NSError(domain:"", code:404, userInfo:nil))
          //seal.fulfill(Ethere
        }
      }
    }
  }
  
  func walletProvider() -> WalletProvider? {
    
    walletAddress.flatMap { account in
      walletConnectSession.map { session in
        
        let client = Client(delegate: self, dAppInfo: session.dAppInfo)
        
        return WalletConnectProvider(
          account: account,
          client: client,
          session: session)
      }
    }
  }
  
}

extension UserWallet: ClientDelegate {
  func client(_ client: Client, didFailToConnect url: WCURL) {
    print("client\(client), url=\(url)")
  }
  
  func client(_ client: Client, didConnect url: WCURL) {
    print("didConnect url client\(client), url=\(url)")
  }
  
  func client(_ client: Client, didConnect session: Session) {
    print("didConnect session=\(session)")
    self.saveWalletConnectSession(session: session)
    
    session.walletInfo?.accounts[safe:0].flatMap {
      try? EthereumAddress(hex:$0,eip55: false)
    }.map {
      self.saveWalletConnectSession(session: session)
      self.saveWalletAddress(address: $0)
    }
  }
  
  func client(_ client: Client, didDisconnect session: Session) {
    print("client didDisconnect")
    self.removeWalletConnectSession()
  }
  
  func client(_ client: Client, didUpdate session: Session) {
    print("client didUpdate, session=\(session)")
  }
}

extension WCURL {
  var fullyPercentEncodedStr: String {
    absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
  }
}
