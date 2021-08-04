//
//  UserSettingsView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/3/21.
//

import SwiftUI

struct UserSettingsView: View {
  @StateObject var userSettings = UserSettings()
  
  @State private var dappBrowserIndex = 0
  
  var body: some View {
    NavigationView {
      VStack {
        ConnectWalletSheet()
        Form {
          Section(header: Text("Preferences")) {
            Picker(selection: $dappBrowserIndex, label: Text("Dapp Browser")) {
              ForEach(0 ..< UserSettings.DappBrowser.allCases.count) {
                Text(UserSettings.DappBrowser.allCases[$0].rawValue)
              }
            }.onChange(of: dappBrowserIndex) { tag in
              userSettings.updateDappBrowser(
                dappBrowser:UserSettings.DappBrowser.allCases[tag]
              )
            }
          }
        }
      }
      .navigationBarTitle("Settings",displayMode: .inline)
    }
    .onAppear {
      userSettings.dappBrowser
        .flatMap { UserSettings.DappBrowser.allCases.firstIndex(of: $0) }
        .map { self.dappBrowserIndex = $0 }
    }
  }
}

struct UserSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    UserSettingsView()
  }
}
