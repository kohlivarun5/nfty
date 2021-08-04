//
//  UserSettingsModel.swift
//  NFTY
//
//  Created by Varun Kohli on 8/3/21.
//

import Foundation

class UserSettings: ObservableObject {
  
  enum DappBrowser : String,CaseIterable {
    case Native
    case Opera
    case Metamask
  }
  
  let userSettingsDappBrowserKey = "dappBrowser"
  
  @Published var dappBrowser : DappBrowser?
  init() {
    dappBrowser =
      UserDefaults.standard.string(forKey: userSettingsDappBrowserKey)
      .flatMap { DappBrowser(rawValue: $0) }
  }
  
  func updateDappBrowser(dappBrowser:DappBrowser) {
    UserDefaults.standard.set(dappBrowser.rawValue,forKey: userSettingsDappBrowserKey)
    self.dappBrowser = dappBrowser
  }
}
