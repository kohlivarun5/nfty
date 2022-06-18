//
//  LoadingProtocol.swift
//  NFTY
//
//  Created by Varun Kohli on 6/18/22.
//

import Foundation


struct LoadingProgress {
  let current : Int
  let total : Int
}

enum LoadingState {
  case uninitialized
  case notLoading
  case loading(LoadingProgress)
}
