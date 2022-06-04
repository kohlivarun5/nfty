//
//  PromiseUtils.swift
//  NFTY
//
//  Created by Varun Kohli on 6/4/22.
//

import Foundation
import PromiseKit

func reduce_p<Element,Result>(_ items:Array<Element>,
                              _ initialResult: Result,
                              _ nextPartialResult: @escaping (Result, Element) -> Promise<Result>) -> Promise<Result> {
  
  return items.reduce(Promise.value(initialResult), { accu,item in
    accu
      .then { accu in
        nextPartialResult(accu,item)
          .recover { error -> Promise<Result> in
            print("Error in chain for item=\(item), Error=\(error)");
            return Promise.value(accu)
          }
      }
    
  })
}
