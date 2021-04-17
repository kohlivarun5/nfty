//
//  ContentView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ListView()
        }
        .navigationBarTitle("NFTy", displayMode: .inline)
        .navigationBarHidden(true)
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
