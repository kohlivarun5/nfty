//
//  SheetButton.swift
//  NFTY
//
//  Created by Varun Kohli on 7/11/21.
//

import SwiftUI

struct SheetButton<ButtonView,SheetView> : View where ButtonView:View, SheetView : View {
  @State private var showSheet = false
  
  private let content : () -> ButtonView
  private let sheetContent : () -> SheetView
  
  init(@ViewBuilder content:@escaping () -> ButtonView,@ViewBuilder sheetContent: @escaping () -> SheetView) {
    self.content = content
    self.sheetContent = sheetContent
  }
  
  var body: some View {
    Button(action: { self.showSheet = true },label:content)
      .sheet(isPresented: $showSheet,
             content: {
              sheetContent()
                // .preferredColorScheme(.dark)
                .accentColor(.orange)
             }
      )
  }
}

struct SheetButton_Previews: PreviewProvider {
  static var previews: some View {
    SheetButton(content:{Text("")},sheetContent: { Text("")})
  }
}
