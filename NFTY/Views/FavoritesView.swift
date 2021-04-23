//
//  FavoritesView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/23/21.
//

import SwiftUI
import Firebase
import Web3

extension UIAlertController {
  convenience init(alert: TextAlert) {
    self.init(title: alert.title, message: nil, preferredStyle: .alert)
    addTextField { $0.placeholder = alert.placeholder }
    addAction(UIAlertAction(title: alert.cancel, style: .cancel) { _ in
      alert.action(nil)
    })
    let textField = self.textFields?.first
    addAction(UIAlertAction(title: alert.accept, style: .default) { _ in
      alert.action(textField?.text)
    })
  }
}



struct AlertWrapper<Content: View>: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  let alert: TextAlert
  let content: Content
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<AlertWrapper>) -> UIHostingController<Content> {
    UIHostingController(rootView: content)
  }
  
  final class Coordinator {
    var alertController: UIAlertController?
    init(_ controller: UIAlertController? = nil) {
      self.alertController = controller
    }
  }
  
  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }
  
  
  func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: UIViewControllerRepresentableContext<AlertWrapper>) {
    uiViewController.rootView = content
    if isPresented && uiViewController.presentedViewController == nil {
      var alert = self.alert
      alert.action = {
        self.isPresented = false
        self.alert.action($0)
      }
      context.coordinator.alertController = UIAlertController(alert: alert)
      uiViewController.present(context.coordinator.alertController!, animated: true)
    }
    if !isPresented && uiViewController.presentedViewController == context.coordinator.alertController {
      uiViewController.dismiss(animated: true)
    }
  }
}

public struct TextAlert {
  public var title: String
  public var placeholder: String = ""
  public var accept: String = "OK"
  public var cancel: String = "Cancel"
  public var action: (String?) -> ()
}

extension View {
  public func alert(isPresented: Binding<Bool>, _ alert: TextAlert) -> some View {
    AlertWrapper(isPresented: isPresented, alert: alert, content: self)
  }
}

struct FavoritesView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  private var firebase: DatabaseReference = Database.database().reference()
  
  @State private var walletAddress = ""
  @State private var isShowingAlert = false
  
  private var info : CollectionInfo
  
  @ObservedObject var recentTrades : NftRecentTradesObject
  
  @State private var showSorted = false
  @State private var filterZeros = false
  @State private var selectedNumber = 0
  
  
  
  
  @State private var action: String? = ""
  
  init(collection:Collection) {
    self.info = collection.info;
    self.recentTrades = collection.data.recentTrades;
  }
  
  func sorted(l:[NFT]) -> [NFT] {
    showSorted ? l.sorted(by:{$0.eth < $1.eth}) : l
  }
  func filtered(l:[NFT]) -> [NFT] {
    filterZeros ? l.filter({$0.eth != 0}) : l
  }
  
  struct FillAll: View {
    let color: Color
    
    var body: some View {
      GeometryReader { proxy in
        self.color.frame(width: proxy.size.width * 1.3).fixedSize()
      }
    }
  }
  
  var body: some View {
    
    ScrollView {
      LazyVStack(pinnedViews:[.sectionHeaders]){
        Section(header:
                  ZStack {
                    
                    VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
                      .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                      HStack {
                        Text("Address")
                        Spacer()
                        Text(walletAddress)
                      }
                      .padding()
                    }
                  }
        ) {
          
          let data = sorted(l:filtered(l:recentTrades.recentTrades));
          ForEach(data.indices,id: \.self) { index in
            let nft = data[index];
            let samples = [info.url1,info.url2,info.url3,info.url4];
            ZStack {
              RoundedImage(nft:nft,samples:samples,themeColor:info.themeColor)
                .padding()
                .onTapGesture {
                  //perform some tasks if needed before opening Destination view
                  self.action = nft.tokenId
                }
              
              NavigationLink(destination: NftDetail(nft:nft,samples:samples,themeColor:info.themeColor),tag:nft.tokenId,selection:$action) {}
                .hidden()
            }.onAppear {
              self.recentTrades.getRecentTrades(currentIndex:index);
            }
          }
        }.textCase(nil)
      }
    }
    .navigationBarTitle("Favorites",displayMode: .inline)
    .onAppear {
      
      if let address = UserDefaults.standard.string(forKey:WalletFields.address) {
        walletAddress = address
      }
      isShowingAlert = walletAddress.isEmpty
      
      
      self.firebase.child("monsterhunter-e8167").child("Velkhana")
        .observeSingleEvent(of: .value, with: { (snapshot) in
          
          let value = snapshot.value as? NSDictionary
          let hp = value?["HP"] as? Int ?? 0
          
          print(hp)
          
          // ...
        }) { (error) in
          print(error.localizedDescription)
        }
    }
    .alert(isPresented: $isShowingAlert, TextAlert(title: "Wallet Address", action: {
      switch($0) {
        case .some(let address):
          switch (try? EthereumAddress(hex:address, eip55: false)) {
            case .some:
              self.walletAddress = address;
              UserDefaults.standard.set(address, forKey: WalletFields.address)
            default:
              self.presentationMode.wrappedValue.dismiss()
          }
          
        default:
          self.presentationMode.wrappedValue.dismiss()
      }
    }))
    
  }
}
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
      FavoritesView(collection:CryptoPunksCollection)
    }
}
