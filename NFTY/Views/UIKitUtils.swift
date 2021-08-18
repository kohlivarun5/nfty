//
//  UIKitUtils.swift
//  NFTY
//
//  Created by Varun Kohli on 7/10/21.
//

import Foundation

import SwiftUI

public extension Color {
  static let lightText = Color(UIColor.lightText)
  static let darkText = Color(UIColor.darkText)
  
  static let label = Color(UIColor.label)
  static let secondaryLabel = Color(UIColor.secondaryLabel)
  static let tertiaryLabel = Color(UIColor.tertiaryLabel)
  static let quaternaryLabel = Color(UIColor.quaternaryLabel)
  
  static let systemBackground = Color(UIColor.systemBackground)
  static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
  static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
  
  static let flatGreen = Color(red: 85/255, green: 239/255, blue: 196/255)
  static let flatOrange = Color(red: 253/255, green: 203/255, blue: 110/255)
  static let flatRed = Color(red: 225/255, green: 112/255, blue: 85/255)
  
  // There are more..
}

struct RoundedCorners: View {
  var color: Color
  var tl: CGFloat = 0.0
  var tr: CGFloat = 0.0
  var bl: CGFloat = 0.0
  var br: CGFloat = 0.0
  
  var body: some View {
    GeometryReader { geometry in
      Path { path in
        
        let w = geometry.size.width
        let h = geometry.size.height
        
        // Make sure we do not exceed the size of the rectangle
        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)
        
        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
      }
      .fill(self.color)
    }
  }
}


extension View {
  func snapshot() -> UIImage {
    let controller = UIHostingController(rootView: self)
    let view = controller.view
    
    let targetSize = controller.view.intrinsicContentSize
    view?.bounds = CGRect(origin: .zero, size: targetSize)
    view?.backgroundColor = .clear
    
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    
    return renderer.image { _ in
      view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
  }
}


import UIKit

struct DocumentPreview: UIViewControllerRepresentable {
  private var isActive: Binding<Bool>
  private let viewController = UIViewController()
  private let docController: UIDocumentInteractionController
  
  init(_ isActive: Binding<Bool>, url: URL) {
    self.isActive = isActive
    self.docController = UIDocumentInteractionController(url: url)
  }
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPreview>) -> UIViewController {
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<DocumentPreview>) {
    if self.isActive.wrappedValue && docController.delegate == nil { // to not show twice
      docController.delegate = context.coordinator
      self.docController.presentPreview(animated: true)
    }
  }
  
  func makeCoordinator() -> Coordintor {
    return Coordintor(owner: self)
  }
  
  final class Coordintor: NSObject, UIDocumentInteractionControllerDelegate { // works as delegate
    let owner: DocumentPreview
    init(owner: DocumentPreview) {
      self.owner = owner
    }
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
      return owner.viewController
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
      controller.delegate = nil // done, so unlink self
      owner.isActive.wrappedValue = false // notify external about done
    }
  }
}
