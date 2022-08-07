//
//  VideoLoopPlayer.swift
//  NFTY
//
//  Created by Varun Kohli on 8/6/22.
//

// https://schwiftyui.com/swiftui/playing-videos-on-a-loop-in-swiftui/
import SwiftUI
import AVKit
import AVFoundation

class PlayerView: UIView {
  
  // Override the property to make AVPlayerLayer the view's backing layer.
  override static var layerClass: AnyClass { AVPlayerLayer.self }
  
  // The associated player object.
  var player: AVPlayer? {
    get { playerLayer.player }
    set { playerLayer.player = newValue }
  }
  
  private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct VideoLoopPlayer: UIViewRepresentable {
  let item: AVPlayerItem
  let queuePlayer : AVQueuePlayer
  let playerLooper : AVPlayerLooper
  
  init(url:URL) {
    self.item = AVPlayerItem(url: url)
    self.queuePlayer = AVQueuePlayer(playerItem: item)
    self.playerLooper = AVPlayerLooper(player: self.queuePlayer, templateItem: self.item)
    
  }
  
  func makeUIView(context: Context) -> PlayerView {
    let view = PlayerView()
    view.player = queuePlayer
    view.player?.isMuted = true
    view.player?.automaticallyWaitsToMinimizeStalling = true
    view.player?.audiovisualBackgroundPlaybackPolicy = .pauses
    view.player?.play()
    return view
  }
  
  func updateUIView(_ uiView: PlayerView, context: Context) { }
}
