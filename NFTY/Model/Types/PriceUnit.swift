//
//  PriceUnit.swift
//  NFTY
//
//  Created by Varun Kohli on 7/7/22.
//

import Foundation
import BigInt

enum PriceUnit : Codable,Comparable,Equatable {
  case wei(BigUInt)
  case near(BigUInt)
  
  public static func>(a: PriceUnit, b: PriceUnit) -> Bool {
    switch(a,b) {
    case (.wei(let x),.wei(let y)),
      (.near(let x),.near(let y)):
      return x > y
    case (.wei(let wei),.near(let near)):
      return (Double(wei) * 1e6 / Double(near)) > 0.005
    case (.near(let near),wei(let wei)):
      return (Double(wei) * 1e6 / Double(near)) <= 0.005
    }
  }
  
  public static func==(a: PriceUnit, b: PriceUnit) -> Bool {
    switch(a,b) {
    case (.wei(let x),.wei(let y)),
      (.near(let x),.near(let y)):
      return x == y
    case (.wei,.near),
      (.near,wei):
      return false
    }
  }
  
  public static func change(new:PriceUnit,prev:PriceUnit) -> Double? {
    switch(new,prev) {
    case (.wei(let x),.wei(let y)),
      (.near(let x),.near(let y)):
      return (Double(x) - Double(y)) / Double(y)
    case (.wei,.near):
      return nil
    case (.near,wei):
      return nil
    }
  }
}
