//
//  SafariView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/6/22.
//

import SwiftUI
import SafariServices

// https://stackoverflow.com/questions/56518029/how-do-i-use-sfsafariviewcontroller-with-swiftui
struct SafariView: UIViewControllerRepresentable {
  
  let url: URL
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
    return SFSafariViewController(url: url)
  }
  
  func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    
  }
  
}
