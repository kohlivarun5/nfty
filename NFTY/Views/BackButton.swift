//
//  BackButton.swift
//  NFTY
//
//  Created by Varun Kohli on 4/25/21.
//

import SwiftUI


struct BackButton: View {
    var body: some View {
      HStack {
        Image(systemName: "chevron.backward")
          .foregroundColor(Color(UIColor.darkGray))
      }
    }
}

struct BackButton_Previews: PreviewProvider {
    static var previews: some View {
        BackButton()
    }
}
