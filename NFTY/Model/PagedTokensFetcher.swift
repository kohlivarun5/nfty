//
//  PagedTokensFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import Foundation
import PromiseKit

protocol PagedTokensFetcher {
  func fetchNext(offset:UInt,limit:UInt) -> Promise<[Any]>
}
