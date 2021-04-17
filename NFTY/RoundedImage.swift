//
//  RoundedImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct RoundedImage: View {
    var body: some View {
        
        VStack {
            Image("Dracocat")
                .resizable()
                .background(Color.yellow)
            
            
            HStack {
                Text("Dracocat")
                Spacer()
                Text("$25")
            }
            .font(.subheadline)
            .padding()
        }
        
        .border(Color.secondary)
        .frame(width: 200.0, height: 250.0)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(Color.gray, lineWidth: 4))
        .shadow(radius: 3)
        
    }
}

struct RoundedImage_Previews: PreviewProvider {
    static var previews: some View {
        RoundedImage()
    }
}
