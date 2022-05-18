//
//  BackButton.swift
//  NFTY
//
//  Created by Varun Kohli on 4/25/21.
//

import SwiftUI


struct BackButton: View {
  var body: some View {
    Image(systemName: "chevron.backward.circle.fill")
      .foregroundColor(Color(UIColor.darkGray))
      .font(.title3)
  }
}

struct BackButton_Previews: PreviewProvider {
  static var previews: some View {
    BackButton()
  }
}
