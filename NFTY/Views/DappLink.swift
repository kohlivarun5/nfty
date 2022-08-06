//
//  DappLink.swift
//  NFTY
//
//  Created by Varun Kohli on 8/12/21.
//

import SwiftUI

struct DappLink {
  
  
  static func openSeaPath(nft:NFT) -> URLComponents {
    
    if (nft.address == "0xf07468eAd8cf26c752C676E43C814FEe9c8CF402") {
      
      var components = URLComponents()
      components.host = "notlarvalabs.com"
      components.path = "/market/view/phunk/\(nft.tokenId)"
      return components
      
    } else if (nft.address.hasSuffix(".near")) {
      // https://paras.id/token/asac.near::2371/2371
      var components = URLComponents()
      components.host = "paras.id"
      components.path = "/token/\(nft.address)::\(nft.tokenId)/\(nft.tokenId)"
      return components
    } else {
      
      var components = URLComponents()
      components.host = "opensea.io"
      components.path = "/assets/\(nft.address)/\(nft.tokenId)"
      components.queryItems = [URLQueryItem(name: "ref", value: "0xAe71923d145ec0eAEDb2CF8197A08f12525Bddf4")]
      return components
    }
  }
  
  static func openSeaPath(address:String) -> URLComponents {
    
    if (address == "0xf07468eAd8cf26c752C676E43C814FEe9c8CF402") {
      
      var components = URLComponents()
      components.host = "notlarvalabs.com"
      components.path = "cryptophunks/forsale"
      return components
      
    } else if (address.hasSuffix(".near")) {
      // https://paras.id/collection/asac.near
      var components = URLComponents()
      components.host = "paras.id"
      components.path = "/collection/\(address)"
      return components
      
    } else {
      
      var components = URLComponents()
      components.host = "opensea.io"
      components.path = "/assets/\(address)"
      components.queryItems = [URLQueryItem(name: "ref", value: "0xAe71923d145ec0eAEDb2CF8197A08f12525Bddf4")]
      return components
    }
  }
  
  static private func url(_ comps : URLComponents,dappBrowser:UserSettings.DappBrowser) -> URL {
    var components = comps
    switch(dappBrowser) {
    case .Native,.InApp:
      components.scheme = "https"
    case .Metamask:
      components.scheme = "metamask"
    case .Opera:
      components.scheme = "touch-https"
    case .Coinbase:
      // https://docs.cloud.coinbase.com/wallet-sdk/docs/deep-link-into-dapp-browser
      let url = DappLink.url(comps,dappBrowser:.Native) // Get native url and encode it
      components.scheme = "https"
      components.host = "go.cb-w.com"
      components.path = "/dapp"
      components.queryItems = [URLQueryItem(name: "cb_url", value: url.absoluteString)]
    }
    // print(components.url!)
    return components.url!
  }
  
  struct DappLinkView<LabelView>: View  where LabelView:View {
    let destination : URLComponents
    @StateObject var userSettings = UserSettings()
    let label : () -> LabelView
    
    var body: some View {
      switch(userSettings.dappBrowser) {
      case .InApp:
        SheetButton(content: { self.label() }, sheetContent: {
          VStack(spacing:0) {
            WebView(request: URLRequest(url: DappLink.url(destination,dappBrowser: userSettings.dappBrowser)))
            Menu {
              ForEach(UserSettings.DappBrowser.allCases.filter { $0 != .InApp },id:\.self.rawValue) {
                Link($0.rawValue,destination:DappLink.url(destination,dappBrowser:$0))
              }
            } label : {
              Spacer()
              
              Text("Open in Browser")
                .foregroundColor(.black)
                //.font(.caption)
                .bold()
              Spacer()
            }
            .padding(10)
            .background(
              RoundedCorners(
                color: .accentColor,
                tl: 20, tr: 20, bl: 20, br: 20))
            .padding([.leading,.trailing],50)
            .padding(.bottom,25)
            .padding(.top,10)
            .background(Color.secondarySystemBackground)
          }
          .ignoresSafeArea(edges: [.top,.bottom])
        })
        .contextMenu(ContextMenu {
          Link("Open in Browser",destination:DappLink.url(destination,dappBrowser: userSettings.dappBrowser))
        })
      default:
        Link(destination:DappLink.url(destination,dappBrowser: userSettings.dappBrowser)) {
          self.label()
        }
      }
    }
  }
}
