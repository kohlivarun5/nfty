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
import SwiftUI
import WidgetKit

class UserWallet: ObservableObject {
  
  @Environment(\.openURL) var openURL
  
  private let walletConnectKey = "walletConnect"
  private let walletConnectSchemeKey = "walletConnectScheme"
  private let walletSignatureKey = "Sign-In" // This key is important as it is also the signed message
  
  @Published var walletNearAddress : String?
  @Published var walletEthAddress : EthereumAddress?
  @Published var walletConnectSession : Session?
  @Published var walletSignature : String?
  
  @Published var walletConnectScheme : String?
  
  @Published var signedIn : Bool = false // SIgned in if walletSignure matches walletAddress
  
  @Published var walletProvider : WalletProvider?
  
  init() {
    if let addr = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys
                                                            .walletAddress.rawValue) {
      self.walletEthAddress = try? EthereumAddress(hex:addr,eip55: false)
    } else {
      self.walletEthAddress = nil
    }
    
    if let nearAccount = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys
                                                            .nearAccount.rawValue) {
      self.walletNearAddress = nearAccount
    } else {
      self.walletNearAddress = nil
    }
    
    if let oldSessionObject = UserDefaults.standard.object(forKey: walletConnectKey) as? Data {
      self.walletConnectSession = try? JSONDecoder().decode(Session.self, from: oldSessionObject)
    }
    
    self.walletSignature = UserDefaults.standard.string(forKey:walletSignatureKey)
    self.walletConnectScheme = UserDefaults.standard.string(forKey:walletConnectSchemeKey)
    signIn()
  }
  
  func saveWalletAddress(address:EthereumAddress) {
    NSUbiquitousKeyValueStore.default.set(address.hex(eip55:true), forKey:CloudDefaultStorageKeys.walletAddress.rawValue)
    DispatchQueue.main.async {
      self.walletEthAddress = address
      self.signIn()
    }
    WidgetCenter.shared.reloadAllTimelines()
  }
  
  func saveNearAccount(account:String) {
    NSUbiquitousKeyValueStore.default.set(account, forKey:CloudDefaultStorageKeys.nearAccount.rawValue)
    DispatchQueue.main.async {
      self.walletNearAddress = account
    }
    //WidgetCenter.shared.reloadAllTimelines()
  }
  
  func saveWalletConnectSession(session:Session,signature:String) {
    let sessionData = try! JSONEncoder().encode(session)
    UserDefaults.standard.set(sessionData, forKey:walletConnectKey)
    UserDefaults.standard.set(signature, forKey:walletSignatureKey)
    DispatchQueue.main.async {
      self.walletConnectSession = session
      self.walletSignature = signature
      self.signIn()
    }
  }
  
  func removeWalletConnectSession() {
    UserDefaults.standard.removeObject(forKey:walletConnectKey)
    UserDefaults.standard.removeObject(forKey:walletSignatureKey)
    DispatchQueue.main.async {
      self.walletConnectSession = nil
      self.walletSignature = nil
      self.signIn()
    }
  }
  
  private func signIn() {
    let signedAddress = recoverSignedAddress()
    DispatchQueue.main.async {
      self.signedIn = signedAddress != nil && signedAddress == self.walletEthAddress
      self.walletProvider = self.makeWalletProvider()
    }
  }
  
  func recoverSignedAddress() -> EthereumAddress? {
    return walletSignature.flatMap {
      Web3Utils.personalECRecover(walletSignatureKey,signature: $0)
    }
  }
  
  private func getConnectionUrl(scheme: String,wcUrl:WCURL) throws -> String {
    
    switch(scheme) {
    case "metamask:":
      // https://github.com/WalletConnect/WalletConnectSwift/issues/79#issuecomment-1007324661
      
      let _encodeURL = wcUrl.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
      let _end2 = _encodeURL.replacingOccurrences(of: "=", with: "%3D").replacingOccurrences(of: "&", with: "%26")
      
      let metamaskLink = "https://metamask.app.link/wc?uri="
      return "\(metamaskLink)\(_end2)"
    case "rainbow:":
      // https://github.com/WalletConnect/WalletConnectSwift/issues/79#issuecomment-1007324661
      
      let _encodeURL = wcUrl.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
      let _end2 = _encodeURL.replacingOccurrences(of: "=", with: "%3D").replacingOccurrences(of: "&", with: "%26")
      
      let metamaskLink = "https://rnbwapp.com/wc?uri="
      return "\(metamaskLink)\(_end2)"
    default:
      let uri = wcUrl.fullyPercentEncodedStr
      var delimiter: String
      if scheme.contains("http") {
        delimiter = "/"
      } else {
        delimiter = "//"
      }
      let redirect = "www.nftygo.com".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
      return "\(scheme)\(delimiter)wc?uri=\(uri)&redirectUrl=\(redirect)"
    }
    
    
  }
  
  func connectToWallet(scheme: String) throws -> Void {
    let wcUrl = connect()
    let urlStr = try! getConnectionUrl(scheme: scheme, wcUrl: wcUrl)
    let url = URL(string: urlStr)!
    // we need a delay so that WalletConnectClient can send handshake request
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
      UserDefaults.standard.set(scheme,forKey:self.walletConnectSchemeKey)
      self.walletConnectScheme = scheme
      print("Launching=\(url)")
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
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
                                        icons: [URL(string:"https://nftygo.com/images/favicons/favicon.ico")!],
                                        url: URL(string: "www.nftygo.com")!)
    let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
    let client = Client(delegate: self, dAppInfo: dAppInfo)
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
        
    @Environment(\.openURL) var openURL
    
    let ethAddress : EthereumAddress
    var nearAddress: String?
    let client : Client
    let session : Session
    let scheme : String
    
    func sendTransaction(tx: EthereumTransaction) -> Promise<EthereumData> {
      let transaction = Client.Transaction(
        from:tx.from!.hex(eip55: true),
        to:tx.to?.hex(eip55: true),
        data:tx.data.hex(),
        gas:tx.gas?.hex(),
        gasPrice:tx.gasPrice?.hex(),
        value:tx.value?.hex(),
        nonce: tx.nonce?.hex(),
        type: nil,
        accessList: nil,
        chainId: nil,
        maxPriorityFeePerGas: nil,
        maxFeePerGas: nil

      )
      try! client.reconnect(to: session)
      
      
      let p = Promise<EthereumData> { seal in
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
          
          try! client.eth_sendTransaction(
            url: session.url,
            transaction: transaction)
          { res in
            
            if let error = res.error {
              return seal.reject(error)
            }
            
            // {"id":1658194250144294,"jsonrpc":"2.0","result":"0xf32a79bbf382fb7eba225fe54c1c4027c5719fb8b0a1b8d3423f338835afd607"}
            struct Response : Decodable {
              let result : String
            }
            
            do {
              let response = try res.result(as:Response.self)
              let txHash = try EthereumData(ethereumValue: EthereumValue(ethereumValue: response.result))
              seal.fulfill(txHash)
            } catch {
              seal.reject(error)
            }
          }
        }
        
        let wcUrl = "wc:\(session.url.topic)@\(session.url.version)"
        let uri = wcUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        var delimiter: String
        if scheme.contains("http") {
          delimiter = "/"
        } else {
          delimiter = "//"
        }
               
        let redirect = "www.nftygo.com".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        let url = URL(string:"\(scheme)\(delimiter)wc?uri=\(uri)&redirectUrl=\(redirect)")!
        print(url)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
          openURL(url)
        }
      }
      
      return p
    }
    
  }
  
  private func makeWalletProvider() -> WalletProvider? {
    
    walletEthAddress.flatMap { account in
      self.walletConnectScheme.flatMap { scheme in
        walletConnectSession.map { session in
          
          let client = Client(delegate: self, dAppInfo: session.dAppInfo)
          return WalletConnectProvider(
            ethAddress: account,
            client: client,
            session: session,
            scheme:scheme)
        }
      }
    }
  }
  
  public func userAccount() -> UserAccount? {
    return self.walletEthAddress.map { UserAccount(ethAddress: $0, nearAccount: self.walletNearAddress) }
  }
  
}

extension UserWallet: ClientDelegate {
  func client(_ client: Client, didFailToConnect url: WCURL) {
    print("WalletConnect client\(client), url=\(url)")
  }
  
  func client(_ client: Client, didConnect url: WCURL) {
    print("WalletConnect didConnect url client\(client), url=\(url)")
  }
  
  func client(_ client: Client, didConnect session: Session) {
    print("WalletConnect didConnect session=\(session)")
    session.walletInfo?.accounts[safe:0].flatMap {
      try? EthereumAddress(hex:$0,eip55: false)
    }.map { address in
      self.saveWalletAddress(address:address)
      // Once we have the connection, sign message to keep
      
      if (self.recoverSignedAddress() != address) {
        self.walletConnectScheme.map { scheme in
          
          try! client.personal_sign(
            url: session.url,
            message: self.walletSignatureKey,
            account: address.hex(eip55: true)
          ) { response in
            (try? response.result(as: String.self)).map {
              self.saveWalletConnectSession(session: session,signature:$0)
            }
          }
          
          let uri = "wc:\(session.url.topic)@\(session.url.version)"
          
          let redirect = "www.nftygo.com".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
          
          let url = URL(string:"\(scheme)//wc?uri=\(uri)&redirectUrl=\(redirect)")!
          
          print(url)
          DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { self.openURL(url) }
        }
      }
        
    }
  }
  
  func client(_ client: Client, didDisconnect session: Session) {
    print("WalletConnect client didDisconnect")
    self.removeWalletConnectSession()
  }
  
  func client(_ client: Client, didUpdate session: Session) {
    print("WalletConnect client didUpdate, session=\(session)")
  }
}

extension WCURL {
  var fullyPercentEncodedStr: String {
    absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
  }
}
