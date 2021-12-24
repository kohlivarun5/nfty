//
//  UserSettingsView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/3/21.
//

import SwiftUI

struct UserSettingsView: View {
  @ObservedObject var userWallet : UserWallet
  @StateObject var userSettings = UserSettings()
  
  @State private var dappBrowserIndex = 0
  @State private var quoteTypeIndex = 0
  
  var body: some View {
    NavigationView {
      VStack {
        ConnectWalletSheet(userWallet:userWallet)
        Form {
          Section(header: Text("Preferences")) {
            Picker(selection: $dappBrowserIndex, label: Text("Dapp Browser")) {
              ForEach(0 ..< UserSettings.DappBrowser.allCases.count) {
                Text(UserSettings.DappBrowser.allCases[$0].rawValue)
              }
            }
            .onChange(of: dappBrowserIndex) { tag in
              userSettings.updateDappBrowser(
                dappBrowser:UserSettings.DappBrowser.allCases[tag]
              )
            }
            
            VStack {
              Text("Display Price In")
              Picker(selection: $quoteTypeIndex,label:Text("Display Price In")) {
                ForEach(0 ..< UserSettings.QuoteType.allCases.count) {
                  Text(UserSettings.QuoteType.allCases[$0].rawValue)
                }
              }
              .pickerStyle(SegmentedPickerStyle())
              .colorMultiply(.orange)
              .onChange(of: quoteTypeIndex) { tag in
                userSettings.updateQuoteType(
                  quoteType:UserSettings.QuoteType.allCases[tag]
                )
              }
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
      
      UserSettings.QuoteType.allCases.firstIndex(of: userSettings.quoteType)
        .map { self.quoteTypeIndex = $0 }
    }
  }
}

struct UserSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    UserSettingsView(userWallet:UserWallet())
  }
}
