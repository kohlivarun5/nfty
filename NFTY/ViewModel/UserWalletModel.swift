//
//  UserWalletModel.swift
//  NFTY
//
//  Created by Varun Kohli on 7/31/21.
//

import Foundation
import Web3
import WalletConnect
import WalletConnectSign
import Auth
import PromiseKit
import SwiftUI
import WidgetKit

// Project ID from WalletConnect Cloud - you need to replace this with your own
private let PROJECT_ID = "9d5192c30c18cef1fdd4b75fb57455f5"
private let APP_METADATA = AppMetadata(
    name: "NFTYgo",
    description: "NFTYgo",
    url: "www.nftygo.com",
    icons: ["https://nftygo.com/images/favicons/favicon.ico"]
)

class UserWallet: ObservableObject {
  @Environment(\.openURL) var openURL
  
  private let walletConnectKey = "walletConnectV2"
  private let walletConnectSchemeKey = "walletConnectSchemeV2"
  private let walletSignatureKey = "Sign-In" // This key is important as it is also the signed message
  
  private var signClient: SignClient?
  private var currentSession: Session?
  private var currentTopic: String?
  
  @Published var walletNearAddress: String?
  @Published var walletEthAddress: EthereumAddress?
  @Published var walletSignature: String?
  @Published var walletConnectScheme: String?
  @Published var signedIn: Bool = false
  @Published var walletProvider: WalletProvider?
  
  init() {
    initializeWalletConnect()
    restoreExistingSession()
  }
  
  private func initializeWalletConnect() {
    do {
      let metadata = AppMetadata(
        name: APP_METADATA.name,
        description: APP_METADATA.description,
        url: APP_METADATA.url,
        icons: APP_METADATA.icons
      )
      
      signClient = try SignClient(
        metadata: metadata,
        projectId: PROJECT_ID
      )
      
      signClient?.delegate = self
    } catch {
      print("Error initializing WalletConnect: \(error)")
    }
  }
  
  private func restoreExistingSession() {
    if let addr = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys.walletAddress.rawValue) {
      self.walletEthAddress = try? EthereumAddress(hex: addr, eip55: false)
    }
    
    if let nearAccount = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys.nearAccount.rawValue) {
      self.walletNearAddress = nearAccount
    }
    
    self.walletSignature = UserDefaults.standard.string(forKey: walletSignatureKey)
    self.walletConnectScheme = UserDefaults.standard.string(forKey: walletConnectSchemeKey)
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
  
  func connectToWallet(scheme: String) throws {
    guard let signClient = signClient else { return }
    
    let namespaces: [String: ProposalNamespace] = [
      "eip155": ProposalNamespace(
        chains: ["eip155:1"], // Ethereum mainnet
        methods: [
          "eth_sendTransaction",
          "personal_sign",
          "eth_signTypedData",
        ],
        events: ["chainChanged", "accountsChanged"]
      )
    ]
    
    do {
      let connectParams = ConnectParams(
        requiredNamespaces: namespaces,
        optionalNamespaces: nil
      )
      
      try signClient.connect(params: connectParams) { [weak self] uri in
        guard let uri = uri?.absoluteString else { return }
        
        DispatchQueue.main.async {
          UserDefaults.standard.set(scheme, forKey: self?.walletConnectSchemeKey ?? "")
          self?.walletConnectScheme = scheme
          
          // Format deep link URL based on wallet scheme
          var deepLink: String
          switch scheme {
          case "metamask:":
            deepLink = "https://metamask.app.link/wc?uri=\(uri)"
          case "rainbow:":
            deepLink = "https://rnbwapp.com/wc?uri=\(uri)"
          default:
            let redirect = "www.nftygo.com".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            deepLink = "\(scheme)//wc?uri=\(uri)&redirectUrl=\(redirect)"
          }
          
          if let url = URL(string: deepLink) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
          }
        }
      }
    } catch {
      print("Error connecting: \(error)")
    }
  }
  
  private func requestSignature(from account: EthereumAddress, topic: String) {
    guard let signClient = signClient else { return }
    
    let message = self.walletSignatureKey
    let params = Request(
      topic: topic,
      chainId: "eip155:1",
      method: "personal_sign",
      params: SignParams(message: message, address: account.hex(eip55: true))
    )
    
    try? signClient.request(params: params) { [weak self] response in
      switch response {
      case .response(let result):
        if let signature = result as? String {
          self?.saveWalletConnectSession(signature: signature)
        }
      case .error(let error):
        print("Error signing message: \(error)")
      }
    }
  }
  
  private func saveWalletConnectSession(signature: String) {
    UserDefaults.standard.set(signature, forKey: walletSignatureKey)
    DispatchQueue.main.async {
      self.walletSignature = signature
      self.signIn()
    }
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
    let bridgeUrl =  "https://safe-walletconnect.safe.global/"
      // https://safe-walletconnect.gnosis.io/
      // https://wcbridge.zerion.io"
      // https://bridge.walletconnect.org
    
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
    let signClient: SignClient
    let topic: String
    let scheme: String
    
    func sendTransaction(tx: EthereumTransaction) -> Promise<EthereumData> {
      return Promise<EthereumData> { seal in
        let transaction = [
          "from": tx.from!.hex(eip55: true),
          "to": tx.to?.hex(eip55: true) ?? "",
          "data": tx.data.hex(),
          "gas": tx.gasLimit?.hex() ?? "",
          "gasPrice": tx.gasPrice?.hex() ?? "",
          "value": tx.value?.hex() ?? "",
          "nonce": tx.nonce?.hex() ?? ""
        ]
        
        let request = Request(
          topic: topic,
          chainId: "eip155:1",
          method: "eth_sendTransaction",
          params: [transaction]
        )
        
        try? signClient.request(params: request) { response in
          switch response {
          case .response(let result):
            if let txHash = result as? String,
               let data = try? EthereumData(ethereumValue: EthereumValue(ethereumValue: txHash)) {
              seal.fulfill(data)
            } else {
              seal.reject(WalletConnectError.invalidResponse)
            }
          case .error(let error):
            seal.reject(error)
          }
        }
        
        // Open wallet app to approve transaction
        let uri = "wc:\(topic)"
        let redirect = "www.nftygo.com".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        if let url = URL(string: "\(scheme)//wc?uri=\(uri)&redirectUrl=\(redirect)") {
          DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            openURL(url)
          }
        }
      }
    }
  }
  
  enum WalletConnectError: Error {
    case invalidResponse
  }
  
  private func makeWalletProvider() -> WalletProvider? {
    guard let signClient = signClient,
          let topic = currentTopic,
          let scheme = walletConnectScheme,
          let account = walletEthAddress else {
      return nil
    }
    
    return WalletConnectProvider(
      ethAddress: account,
      signClient: signClient,
      topic: topic,
      scheme: scheme
    )
  }
  
  public func userAccount() -> UserAccount? {
    return self.walletEthAddress.map { UserAccount(ethAddress: $0, nearAccount: self.walletNearAddress) }
  }
}

extension UserWallet: SignClientDelegate {
  func signClient(_ signClient: WalletConnect.SignClient, didUpdateSession session: WalletConnect.Session) {
    print("WalletConnect session updated: \(session)")
    
    // Update the current session
    self.currentSession = session
    self.currentTopic = session.topic
    
    // Update accounts if changed
    if let account = session.accounts.first,
       let address = account.address,
       let ethAddress = try? EthereumAddress(hex: address, eip55: false) {
      self.saveWalletAddress(address: ethAddress)
    }
  }
  
  func signClient(_ signClient: WalletConnect.SignClient, didReceiveSessionDelete sessionDelete: WalletConnect.Session) {
    print("WalletConnect session deleted")
    self.removeWalletConnectSession()
  }
  
  func signClient(_ signClient: WalletConnect.SignClient, didReceiveSessionProposal sessionProposal: WalletConnect.Session.Proposal) {
    print("WalletConnect session proposal received: \(sessionProposal)")
  }
  
  func signClient(_ signClient: WalletConnect.SignClient, didReceiveSessionRequest sessionRequest: WalletConnect.Request) {
    print("WalletConnect session request received: \(sessionRequest)")
  }
  
  func signClient(_ signClient: WalletConnect.SignClient, didSettleSession session: WalletConnect.Session) {
    print("WalletConnect session settled: \(session)")
    
    self.currentSession = session
    self.currentTopic = session.topic
    
    // Get the Ethereum address from the session
    if let account = session.accounts.first,
       let address = account.address,
       let ethAddress = try? EthereumAddress(hex: address, eip55: false) {
      self.saveWalletAddress(address: ethAddress)
      
      // Request signature if needed
      if self.recoverSignedAddress() != ethAddress {
        self.requestSignature(from: ethAddress, topic: session.topic)
      }
    }
  }
}

extension WCURL {
  var fullyPercentEncodedStr: String {
    absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
  }
}
