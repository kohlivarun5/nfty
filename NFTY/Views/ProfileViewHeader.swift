//
//  ProfileViewHeader.swift
//  NFTY
//
//  Created by Varun Kohli on 5/17/22.
//

import SwiftUI

struct ProfileViewHeader: View {
  
  let name : String?
  let account : UserAccount
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Image("SAMPLE_MAYC")
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 100, height: 100)
          .clipped()
          .cornerRadius(10)
        VStack(alignment: .leading) {
          Text("Article by")
            .font(.custom("AvenirNext-Regular", size: 15))
            .foregroundColor(.gray)
          
          name.map { Text($0).bold() }
          WalletOverview(account:account)
        }
        Spacer()
      }
    }
  }
}
