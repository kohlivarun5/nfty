//
//  ProfileAvatarImage.swift
//  NFTY
//
//  Created by Varun Kohli on 7/17/22.
//

import SwiftUI

struct ProfileAvatarImage: View {
  
  let nft : NFT
  let collection : Collection
  let size : NftImage.Size
    
  var body: some View {
    NftImage(
      nft:nft,
      sample:collection.info.sample,
      themeColor:collection.info.themeColor,
      themeLabelColor:collection.info.themeLabelColor,
      size:size,
      resolution:.hd,
      favButton:.none)
    .border(Color.secondary)
    .clipShape(Circle())
    .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
    .shadow(color:.accentColor,radius:0)
  }
}
