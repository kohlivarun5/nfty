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
  
  var body: some View {
    NavigationView {
      VStack {
        ConnectWalletSheet(userWallet:userWallet)
        Form {
          Section(header: Text("Preferences")) {
            Picker(
              selection: Binding<String>(
                get: { self.userSettings.dappBrowser.rawValue },
                set: { tag in
                  withAnimation { // needed explicit for transitions
                    userSettings.updateDappBrowser(
                      dappBrowser: UserSettings.DappBrowser(rawValue:tag)!
                    )
                  }
                }),
              label: Text("Dapp Browser")) {
                ForEach(UserSettings.DappBrowser.allCases,id:\.self.rawValue) { item in
                  Text(item.rawValue)
                }
              }
            
            VStack {
              Text("Display Price In")
              Picker(
                selection: Binding<String>(
                  get: { self.userSettings.quoteType.rawValue },
                  set: { tag in
                    withAnimation { // needed explicit for transitions
                      userSettings.updateQuoteType(
                        quoteType:UserSettings.QuoteType(rawValue:tag)!
                      )
                    }
                  }),
                label:Text("Display Price In")) {
                  ForEach(UserSettings.QuoteType.allCases,id:\.self.rawValue) { item in
                    Text(item.rawValue)
                  }
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorMultiply(.orange)
            }
            
            
            Picker(
              selection: Binding<String>(
                get: { self.userSettings.offerNotificationMinimum.rawValue },
                set: { tag in
                  withAnimation { // needed explicit for transitions
                    userSettings.updateOfferNotificationMinimum(
                      offerNotificationMinimum:UserSettings.OfferNotificationMinimumType(rawValue:tag)!
                    )
                  }
                }),
              label:Text("Offer Notification Limit")) {
                ForEach(UserSettings.OfferNotificationMinimumType.allCases,id:\.self.rawValue) { item in
                  Text(item.rawValue)
                }
              }
          }
        }
      }
      .navigationBarTitle("Settings",displayMode: .inline)
    }
  }
}

struct UserSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    UserSettingsView(userWallet:UserWallet())
  }
}
