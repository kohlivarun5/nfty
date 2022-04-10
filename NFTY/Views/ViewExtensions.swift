//
//  ViewExtensions.swift
//  NFTY
//
//  Created by Varun Kohli on 4/10/22.
//

import SwiftUI


struct Theme: ViewModifier {
  func body(content: Content) -> some View {
    content
      //.preferredColorScheme(.dark)
      .accentColor(Color.orange)
  }
}


extension View {
  /// Applies the given transform if the given condition evaluates to `true`.
  /// - Parameters:
  ///   - condition: The condition to evaluate.
  ///   - transform: The transform to apply to the source `View`.
  /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
  @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
  
  func themeStyle() -> some View {
    modifier(Theme())
  }
}
