//
//  SVGImage.swift
//  NFTY
//
//  Created by Varun Kohli on 7/10/22.
//

import SwiftUI
import SVGKit

struct SVGKFastImageViewSUI:UIViewRepresentable
{
  let data : Data
  // @Binding var size:CGSize
  
  func makeUIView(context: Context) -> SVGKFastImageView {
    
    // let url = url
    //  let data = try? Data(contentsOf: url)
    let svgImage = SVGKImage(data:self.data)
    return SVGKFastImageView(svgkImage: svgImage ?? SVGKImage())
    
  }
  func updateUIView(_ uiView: SVGKFastImageView, context: Context) {
    uiView.image = SVGKImage(data:self.data)
    // uiView.image.size = size
  }
}
