//
//  ContentView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            MapView()
                .ignoresSafeArea(edges: .top)
                .frame(height:300)
            RoundedImage(nft:nfts[0])
                .offset(y: -130)
                .padding(.bottom, -130)
            VStack(alignment:.leading) {
                Text("NFTY")
                    .font(.title)
                    .foregroundColor(Color.purple)
                HStack {
                    Text(/*@START_MENU_TOKEN@*/"NFTs for All"/*@END_MENU_TOKEN@*/)
                    Spacer()
                    Text("Open Crypto")
                }
                .font(.headline)
                Divider()

               Text("About Turtle Rock")
                   .font(.title2)
               Text("Descriptive text goes here.")
            }
            .padding()
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
