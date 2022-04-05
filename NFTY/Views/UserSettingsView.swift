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
  @State private var offerNotificationIndex = 0
  
  var body: some View {
    NavigationView {
      VStack {
        ConnectWalletSheet(userWallet:userWallet)
        Form {
          Section(header: Text("Preferences")) {
            Picker(selection: $dappBrowserIndex, label: Text("Dapp Browser")) {
              ForEach(UserSettings.DappBrowser.allCases,id:\.self.rawValue) { item in
                Text(item.rawValue)
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
                ForEach(UserSettings.QuoteType.allCases,id:\.self.rawValue) { item in
                  Text(item.rawValue)
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
            
            
            Picker(
              selection: $offerNotificationIndex,
              label:Text("Offer Notification Limit")) {
                
                ForEach(UserSettings.OfferNotificationMinimumType.allCases,id:\.self.rawValue) { item in
                  Text(item.rawValue)
                }
              }
              .onChange(of: offerNotificationIndex) { tag in
                userSettings.updateOfferNotificationMinimum(
                  offerNotificationMinimum:UserSettings.OfferNotificationMinimumType.allCases[tag]
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
      
      UserSettings.QuoteType.allCases.firstIndex(of: userSettings.quoteType)
        .map { self.quoteTypeIndex = $0 }
      
      UserSettings.OfferNotificationMinimumType.allCases.firstIndex(of: userSettings.offerNotificationMinimum)
        .map { self.offerNotificationIndex = $0 }
    }
  }
}

struct UserSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    UserSettingsView(userWallet:UserWallet())
  }
}
