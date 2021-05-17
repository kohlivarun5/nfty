//
//  WebView.swift
//  Todos
//
//  Created by Bradley Hilton on 6/5/19.
//  Copyright © 2019 Brad Hilton. All rights reserved.
// https://developer.apple.com/forums/thread/117348
//

import SwiftUI
import WebKit

struct WebView : UIViewRepresentable {
  
  let request: URLRequest
  
  func makeUIView(context: Context) -> WKWebView  {
    return WKWebView()
  }
  
  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.load(request)
  }
  
}
