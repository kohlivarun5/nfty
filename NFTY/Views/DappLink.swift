//
//  DappLink.swift
//  NFTY
//
//  Created by Varun Kohli on 8/12/21.
//

import SwiftUI

struct DappLink: View {
  let destination : URLComponents
  @StateObject var userSettings = UserSettings()
  
  static func openSeaPath(nft:NFT) -> URLComponents {
    
    if (nft.address == "0xf07468eAd8cf26c752C676E43C814FEe9c8CF402") {
      
      var components = URLComponents()
      components.host = "notlarvalabs.com"
      components.path = "/market/view/phunk/\(nft.tokenId)"
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
      
    } else {
      
      var components = URLComponents()
      components.host = "opensea.io"
      components.path = "/assets/\(address)"
      components.queryItems = [URLQueryItem(name: "ref", value: "0xAe71923d145ec0eAEDb2CF8197A08f12525Bddf4")]
      return components
    }
  }
  
  static private func url(_ comps : URLComponents,dappBrowser:UserSettings.DappBrowser?) -> URL {
    var components = comps
    switch(dappBrowser) {
    case .none,.some(.Native):
      components.scheme = "https"
    case .some(.Metamask):
      components.scheme = "metamask"
    case .some(.Opera):
      components.scheme = "touch-https"
    }
    return components.url!
  }
  
  static func openSeaUrl(nft:NFT,dappBrowser:UserSettings.DappBrowser?) -> URL {
    DappLink.url(DappLink.openSeaPath(nft: nft),dappBrowser: dappBrowser)
  }
  
  static func openSeaUrl(address:String,dappBrowser:UserSettings.DappBrowser?) -> URL {
    DappLink.url(DappLink.openSeaPath(address: address),dappBrowser: dappBrowser)
  }
  
  var body: some View {
    Link(destination:DappLink.url(destination,dappBrowser: userSettings.dappBrowser)) {
      Image(systemName: "arrow.up.right.square.fill")
        .foregroundColor(.tertiaryLabel)
    }
  }
}

struct DappLink_Previews: PreviewProvider {
  static var previews: some View {
    DappLink(destination: DappLink.openSeaPath(nft: SampleToken))
  }
}
