//
//  SVGImage.swift
//  NFTY
//
//  Created by Varun Kohli on 7/10/22.
//

import SwiftUI
import SVGView

typealias NFTYgoSVGImage = SVGView

let DempSVG = """
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" image-rendering="pixelated" height="336" width="336"><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVR42mNMbp32n4GGgHHUglELRi0YtWDUglELRi0YtWBoWAAAuD470bkESf4AAAAASUVORK5CYII="/></foreignObject><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAtUlEQVRIiWNgGAXDHjASoeY/JfoJKfhfaC+LU7L/4GOCZjARY7iUCD9WBVB5fD7EawHc8GdvPhJSRr4FlBhOlAWUAhZiFJ26/ZiBgYGBwUxVFkOMEMDlA5TUc/QZA4O5LCeKAmxi2ACuJIY3eSIDQkkVZxxANVIMcFmA00X9Bx+TZDlRkYwMiA06GBgcyRQGkIOGWJ+QZAGpwcPAQGEQEVOaEu0DHCmHYH1AaioipoJCATRPRQA6VS3JBLgqewAAAABJRU5ErkJggg==" /></foreignObject><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVRIie3NMQEAAAjDMMC/52ECvlRA00nqs3m9AwAAAAAAAJy1C7oDLddyCRYAAAAASUVORK5CYII=" /></foreignObject><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAcklEQVRIie2RQQrAMAgE15L/f9neSiir1qA9hMwpoGFWBQ7bIwCgql6PV5TnIUIbriCAa/5Qx1j9SHrpCFRgjbsCFQQ3oVihrBUBxshZ2JHz8ZMCoCg9E5SmZ4JyLEHZJLOgfD1vQQu/CVrWMwvaOIKQGwRhECvRC0yWAAAAAElFTkSuQmCC" /></foreignObject><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAL0lEQVRIiWNgGAWjYBSMAoKAkYD8fyqYQZTh/7FYhk0MAzDhkSPbZaNgFIyC4QYAovwGAIP/A58AAAAASUVORK5CYII=" /></foreignObject><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVRIie3NMQEAAAjDMMC/52ECvlRA00nqs3m9AwAAAAAAAJy1C7oDLddyCRYAAAAASUVORK5CYII=" /></foreignObject></svg>
"""

/*
import SVGKit

struct SVGKFastImageViewSUI:UIViewRepresentable
{
  let data : Data
  // @Binding var size:CGSize
  
  func makeUIView(context: Context) -> SVGKFastImageView {
    let svgImage = SVGKImage(data:self.data)
    return SVGKFastImageView(svgkImage: svgImage ?? SVGKImage())
    
  }
  func updateUIView(_ uiView: SVGKFastImageView, context: Context) {
    uiView.image = SVGKImage(data:self.data)
    uiView.image.size = CGSize(width: 400,height: 400)
  }
}



struct SVGImage_Previews: PreviewProvider {
  
  static let svg = """
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="336" width="336">
  <foreignObject x="0" y="0" width="336" height="336">
    <img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVR42mNMbp32n4GGgHHUglELRi0YtWDUglELRi0YtWBoWAAAuD470bkESf4AAAAASUVORK5CYII="/>
  </foreignObject><foreignObject x="0" y="0" width="336" height="336">
    <img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAtUlEQVRIiWNgGAXDHjASoeY/JfoJKfhfaC+LU7L/4GOCZjARY7iUCD9WBVB5fD7EawHc8GdvPhJSRr4FlBhOlAWUAhZiFJ26/ZiBgYGBwUxVFkOMEMDlA5TUc/QZA4O5LCeKAmxi2ACuJIY3eSIDQkkVZxxANVIMcFmA00X9Bx+TZDlRkYwMiA06GBgcyRQGkIOGWJ+QZAGpwcPAQGEQEVOaEu0DHCmHYH1AaioipoJCATRPRQA6VS3JBLgqewAAAABJRU5ErkJggg==" />
  </foreignObject><foreignObject x="0" y="0" width="336" height="336">
    <img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVRIie3NMQEAAAjDMMC/52ECvlRA00nqs3m9AwAAAAAAAJy1C7oDLddyCRYAAAAASUVORK5CYII=" /></foreignObject><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAcklEQVRIie2RQQrAMAgE15L/f9neSiir1qA9hMwpoGFWBQ7bIwCgql6PV5TnIUIbriCAa/5Qx1j9SHrpCFRgjbsCFQQ3oVihrBUBxshZ2JHz8ZMCoCg9E5SmZ4JyLEHZJLOgfD1vQQu/CVrWMwvaOIKQGwRhECvRC0yWAAAAAElFTkSuQmCC" /></foreignObject><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAL0lEQVRIiWNgGAWjYBSMAoKAkYD8fyqYQZTh/7FYhk0MAzDhkSPbZaNgFIyC4QYAovwGAIP/A58AAAAASUVORK5CYII=" /></foreignObject><foreignObject x="0" y="0" width="336" height="336"><img xmlns="http://www.w3.org/1999/xhtml" height="336" width="336" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAJklEQVRIie3NMQEAAAjDMMC/52ECvlRA00nqs3m9AwAAAAAAAJy1C7oDLddyCRYAAAAASUVORK5CYII=" /></foreignObject>
</svg>
"""
  
  static var previews: some View {
    SVGKFastImageViewSUI(data:SVGImage_Previews.svg.data(using: .utf8)!)
  }
}


*/
