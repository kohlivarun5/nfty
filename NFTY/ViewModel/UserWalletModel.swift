//
//  UserWalletModel.swift
//  NFTY
//
//  Created by Varun Kohli on 7/31/21.
//

import Foundation
import Web3
import ReownAppKit
import ReownAppKitUI
import PromiseKit
import SwiftUI
import WidgetKit
import Combine

class UserWallet: ObservableObject {
  
  @Environment(\.openURL) var openURL
  
  private let walletSignatureKey = "Sign-In" // This key is important as it is also the signed message
  
  @Published var walletNearAddress: String?
  @Published var walletEthAddress: EthereumAddress?
  @Published var session: Session?
  @Published var walletSignature: String?
  @Published var signedIn: Bool = false
  @Published var walletProvider: WalletProvider?
  
  private var cancellables = Set<AnyCancellable>()

  init() {
    if let addr = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys.walletAddress.rawValue) {
      self.walletEthAddress = try? EthereumAddress(hex: addr, eip55: false)
    }
    if let nearAccount = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys.nearAccount.rawValue) {
      self.walletNearAddress = nearAccount
    }
    setupAppKitSubscriptions()
    signIn()
  }

  private func setupAppKitSubscriptions() {
    // AppKit does not have sessionPublisher, so use getSessions() and listen to authResponsePublisher only
    AppKit.instance.authResponsePublisher.sink { [weak self] (_, result) in
      switch result {
      case .success((let session, _)):
        if let session = session {
          self?.handleSessionConnect(session)
        }
      case .failure(let error):
        print("Auth error: \(error)")
      }
    }.store(in: &cancellables)
  }

  private func handleSessionConnect(_ session: Session) {
    self.session = session
    // session.accounts is [Account], get .address property
    if let account = session.accounts.first, let address = try? EthereumAddress(hex: account.address, eip55: false) {
      self.saveWalletAddress(address: address)
    }
  }

  func connectToWallet() async throws {
    let _ = try await AppKit.instance.createPairing()
    try await AppKit.instance.connect(walletUniversalLink: nil)
  }

  func disconnect() async throws {
    if let session = session {
      try await AppKit.instance.disconnect(topic: session.topic)
      removeSession()
    }
  }

  private func removeSession() {
    DispatchQueue.main.async {
      self.session = nil
      self.walletSignature = nil
      self.signIn()
    }
  }

  func saveWalletAddress(address: EthereumAddress) {
    NSUbiquitousKeyValueStore.default.set(address.hex(eip55: true), forKey: CloudDefaultStorageKeys.walletAddress.rawValue)
    DispatchQueue.main.async {
      self.walletEthAddress = address
      self.signIn()
    }
    WidgetCenter.shared.reloadAllTimelines()
  }

  func saveNearAccount(account: String) {
    NSUbiquitousKeyValueStore.default.set(account, forKey: CloudDefaultStorageKeys.nearAccount.rawValue)
    DispatchQueue.main.async {
      self.walletNearAddress = account
    }
    //WidgetCenter.shared.reloadAllTimelines()
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
      Web3Utils.personalECRecover(walletSignatureKey, signature: $0)
    }
  }

  struct AppKitWalletProvider: WalletProvider {
    let ethAddress: EthereumAddress
    var nearAddress: String?
    let session: Session

    func sendTransaction(tx: EthereumTransaction) -> Promise<EthereumData> {
      return Promise { seal in
        Task {
          do {
            let transaction = makeTransaction(from: tx)
            let result = try await AppKit.instance.request(
              params: .init(
                topic: session.topic,
                method: "eth_sendTransaction",
                params: AnyCodable(any: [transaction]),
                chainId: Blockchain("eip155:1")!
              )
            )
            if let txHashString = result as? String, let txHash = try? EthereumData(ethereumValue: EthereumValue(ethereumValue: txHashString)) {
              seal.fulfill(txHash)
            } else {
              seal.reject(NSError(domain: "AppKitWalletProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid transaction hash"]))
            }
          } catch {
            seal.reject(error)
          }
        }
      }
    }

    private func makeTransaction(from tx: EthereumTransaction) -> [String: Any] {
      var transaction: [String: Any] = [
        "from": tx.from!.hex(eip55: true)
      ]
      if let to = tx.to?.hex(eip55: true) { transaction["to"] = to }
      transaction["data"] = tx.data.hex()
      if let gas = tx.gasLimit?.hex() { transaction["gas"] = gas }
      if let gasPrice = tx.gasPrice?.hex() { transaction["gasPrice"] = gasPrice }
      if let value = tx.value?.hex() { transaction["value"] = value }
      if let nonce = tx.nonce?.hex() { transaction["nonce"] = nonce }
      return transaction
    }
  }

  private func makeWalletProvider() -> WalletProvider? {
    guard let session = session, let account = walletEthAddress else {
      return nil
    }
    return AppKitWalletProvider(
      ethAddress: account,
      nearAddress: walletNearAddress,
      session: session
    )
  }

  public func userAccount() -> UserAccount? {
    return self.walletEthAddress.map { UserAccount(ethAddress: $0, nearAccount: self.walletNearAddress) }
  }
}
