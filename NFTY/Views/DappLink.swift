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
    var components = URLComponents()
    components.host = "opensea.io"
    components.path = "/assets/\(nft.address)/\(nft.tokenId)"
    return components
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
