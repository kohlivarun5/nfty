//
//  Extensions.swift
//  NFTY
//
//  Created by Varun Kohli on 7/18/21.
//

import Foundation

extension Date {
  
  /// Create a date from specified parameters
  ///
  /// - Parameters:
  ///   - year: The desired year
  ///   - month: The desired month
  ///   - day: The desired day
  /// - Returns: A `Date` object
  static func from(year: Int, month: Int, day: Int) -> Date? {
    let calendar = Calendar(identifier: .gregorian)
    var dateComponents = DateComponents()
    dateComponents.year = year
    dateComponents.month = month
    dateComponents.day = day
    return calendar.date(from: dateComponents) ?? nil
  }
}

extension Array {
  subscript (safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }
}

extension String {
  /*
   Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
   - Parameter length: Desired maximum lengths of a string
   - Parameter trailing: A 'String' that will be appended after the truncation.
   
   - Returns: 'String' object.
   */
  func trunc(length: Int, trailing: String = "…") -> String {
    return (self.count > length) ? self.prefix(length) + trailing : self
  }
  
  func deletingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    return String(self.dropFirst(prefix.count))
  }
  
  func encodeURIComponent() -> String? {
    let characterSet = CharacterSet.init(charactersIn: "@\"!*'();:@&=+$,/?%#[]").inverted
    return self.addingPercentEncoding(withAllowedCharacters: characterSet)
  }
  
  func addHexPrefix() -> String {
    if !self.hasPrefix("0x") {
      return "0x" + self
    }
    return self
  }
  
  func stripHexPrefix() -> String {
    if self.hasPrefix("0x") {
      let indexStart = self.index(self.startIndex, offsetBy: 2)
      return String(self[indexStart...])
    }
    return self
  }
  
}

extension URL {
  func params() -> [String:Any] {
    var dict = [String:Any]()
    
    if let components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
      if let queryItems = components.queryItems {
        for item in queryItems {
          dict[item.name] = item.value!
        }
      }
      return dict
    } else {
      return [:]
    }
  }
}
