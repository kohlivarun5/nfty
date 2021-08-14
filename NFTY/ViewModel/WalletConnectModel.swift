//
//  WalletConnectModel.swift
//  NFTY
//
//  Created by Varun Kohli on 7/24/21.
//

import Foundation
import Web3
import WalletConnectSwift

protocol WalletConnectDelegate {
  func failedToConnect()
  func didConnect(account:EthereumAddress?)
  func didDisconnect()
}

extension WCURL {
  var fullyPercentEncodedStr: String { 
    absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
  }
}

class WalletConnect {
  var client: Client!
  var session: Session!
  var delegate: WalletConnectDelegate
  
  let sessionKey = "\(Bundle.main.bundleIdentifier!).WalletConnect"
  
  init(delegate: WalletConnectDelegate) {
    self.delegate = delegate
    
    if let oldSessionObject = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.walletConnect.rawValue) as? Data,
       let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject) {
      self.client = Client(delegate: self, dAppInfo: session.dAppInfo)
      self.session = session
    }
  }
  
  func connect() -> WCURL {
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
    self.client = Client(delegate: self, dAppInfo: dAppInfo)
    
    print("WalletConnect URL: \(wcUrl.absoluteString)")
    
    try! client.connect(to: wcUrl)
    return wcUrl
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

  func reconnectIfNeeded() {
    if let oldSessionObject = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.walletConnect.rawValue) as? Data,
       let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject) {
      client = Client(delegate: self, dAppInfo: session.dAppInfo)
      try? client.reconnect(to: session)
    }
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
}

extension WalletConnect: ClientDelegate {
  func client(_ client: Client, didFailToConnect url: WCURL) {
    print("client\(client), url=\(url)")
    delegate.failedToConnect()
  }
  
  func client(_ client: Client, didConnect url: WCURL) {
    print("didConnect url client\(client), url=\(url)")
  }
  
  func client(_ client: Client, didConnect session: Session) {
    print("didConnect session=\(session)")
    self.session = session
    let sessionData = try! JSONEncoder().encode(session)
    NSUbiquitousKeyValueStore.default.set(sessionData, forKey: CloudDefaultStorageKeys.walletConnect.rawValue)
    delegate.didConnect(
      account:session.walletInfo?.accounts.first.flatMap {
        try? EthereumAddress(hex:$0,eip55: false)
      })
  }
  
  func client(_ client: Client, didDisconnect session: Session) {
    print("client didDisconnect")
    NSUbiquitousKeyValueStore.default.removeObject(forKey: CloudDefaultStorageKeys.walletConnect.rawValue)
    delegate.didDisconnect()
  }
  
  func client(_ client: Client, didUpdate session: Session) {
    print("client didUpdate, session=\(session)")
    // do nothing
  }
}
