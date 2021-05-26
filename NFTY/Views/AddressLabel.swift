//
//  AddressLabel.swift
//  NFTY
//
//  Created by Varun Kohli on 5/17/21.
//

import SwiftUI

struct AddressLabel: View {
  let address : String
  let maxLen : Int
  
  var body: some View {
    HStack {
      Spacer()
      Text(address.trunc(length:maxLen))
        .font(.system(size:12, design: .monospaced))
        .foregroundColor(.secondary)
      
      Button(action: {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "nftygo.com"
        components.path = "/user"
        components.queryItems = [
          URLQueryItem(name: "address", value: address)
        ]
        guard let urlShare = components.url else { return }
        
        // https://stackoverflow.com/a/64962982
        let shareActivity = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
        if let vc = UIApplication.shared.windows.first?.rootViewController {
          shareActivity.popoverPresentationController?.sourceView = vc.view
          //Setup share activity position on screen on bottom center
          shareActivity.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height, width: 0, height: 0)
          shareActivity.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
          vc.present(shareActivity, animated: true, completion: nil)
        }
      }, label: {
        Image(systemName: "arrowshape.turn.up.forward.circle")
          .foregroundColor(.secondary)
      }).padding(.leading)
    }
  }
}

struct AddressLabel_Previews: PreviewProvider {
  static var previews: some View {
    AddressLabel(address:"0x0",maxLen:30)
  }
}
