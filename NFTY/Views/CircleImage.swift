//
//  CircleImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct CircleImage: View {
    var body: some View {
        Image("Dracocat")
            .resizable()
            .frame(width: 200.0, height: 200.0)
            .background(
                Circle()
                    .fill(Color.yellow)
            )
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            .overlay(Circle().stroke(Color.gray, lineWidth: 4))
            .shadow(radius: 7)
    }
}

struct CircleImage_Previews: PreviewProvider {
    static var previews: some View {
        CircleImage()
    }
}
