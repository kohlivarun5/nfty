//
//  OpenSeaLink.swift
//  NFTY
//
//  Created by Varun Kohli on 5/17/21.
//

import SwiftUI

struct OpenSeaLink: View {
  @StateObject var userSettings = UserSettings()
  @State private var showSheet = false
  
  static func url(nft:NFT,dappBrowser:UserSettings.DappBrowser?) -> URL {
    let path = "opensea.io/assets/\(nft.address)/\(nft.tokenId)"
    switch(dappBrowser) {
    case .none,.some(.Native):
      return URL(string:"https://\(path)")!
    case .some(.Metamask):
      return URL(string:"https://metamask.app.link/dapp/\(path)")!
    case .some(.Opera):
      return URL(string:"touch-https://\(path)")!
    }
  }
  
  let nft : NFT
  var body: some View {
    Button(action: {
      self.showSheet = true
    }) {
      Image(systemName: "arrow.up.right.square.fill")
        .foregroundColor(.tertiaryLabel)
    
    }.sheet(isPresented: $showSheet) {
      WebView(request: URLRequest(url:URL(string:"https://opensea.io/assets/\(nft.address)/\(nft.tokenId)")!))
      
      Link(destination:OpenSeaLink.url(nft:nft,dappBrowser: userSettings.dappBrowser)) {
        HStack(spacing:50) {
          Spacer()
          VStack {
            Text("Open in browser")
              .fontWeight(.semibold)
              .font(.subheadline)
          }
          .frame(minWidth: 0, maxWidth: .infinity)
          .padding(10)
          .foregroundColor(Color.systemBackground)
          .background(Color.blue)
          .cornerRadius(40)
          
          Spacer()
        }
      }
    }
  }
}

struct OpenSeaLink_Previews: PreviewProvider {
  static var previews: some View {
    OpenSeaLink(nft:SampleToken)
  }
}
