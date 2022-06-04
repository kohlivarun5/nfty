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

struct PriceOverlay : ViewModifier {
  @Environment(\.colorScheme) var colorScheme
  func body(content:Content) -> some View {
    content
      .if(colorScheme != .dark) { $0.colorMultiply(.accentColor) }
      .background(RoundedCorners(color:colorScheme == .dark
                                 ? .tertiarySystemBackground.opacity(0.75)
                                 : .systemBackground.opacity(0.7),
                                 tl: 5, tr: 5, bl: 5, br: 5))
      .if( colorScheme == .dark) { $0.colorMultiply(.accentColor) }
      .shadow(color: (colorScheme != .dark ? Color.accentColor : .systemBackground).opacity(0.75),
              radius:1)
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


public struct ForEachWithIndex<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
  public var data: Data
  public var content: (_ index: Data.Index, _ element: Data.Element) -> Content
  var id: KeyPath<Data.Element, ID>
  
  public init(_ data: Data, id: KeyPath<Data.Element, ID>, content: @escaping (_ index: Data.Index, _ element: Data.Element) -> Content) {
    self.data = data
    self.id = id
    self.content = content
  }
  
  public var body: some View {
    ForEach(
      zip(self.data.indices, self.data).map { index, element in
        IndexInfo(
          index: index,
          id: self.id,
          element: element
        )
      },
      id: \.elementID
    ) { indexInfo in
      self.content(indexInfo.index, indexInfo.element)
    }
  }
}

extension ForEachWithIndex where ID == Data.Element.ID, Content: View, Data.Element: Identifiable {
  public init(_ data: Data, @ViewBuilder content: @escaping (_ index: Data.Index, _ element: Data.Element) -> Content) {
    self.init(data, id: \.id, content: content)
  }
}

extension ForEachWithIndex: DynamicViewContent where Content: View {
}

private struct IndexInfo<Index, Element, ID: Hashable>: Hashable {
  let index: Index
  let id: KeyPath<Element, ID>
  let element: Element
  
  var elementID: String {
    "\(self.index):\(self.element[keyPath: self.id])"
  }
  
  static func == (_ lhs: IndexInfo, _ rhs: IndexInfo) -> Bool {
    lhs.elementID == rhs.elementID
  }
  
  func hash(into hasher: inout Hasher) {
    self.elementID.hash(into: &hasher)
  }
}
