//
//  CloudKitExtensions.swift
//  NFTY
//
//  Created by Varun Kohli on 6/7/22.
//

import Foundation
import CloudKit
import PromiseKit


// https://github.com/JunDang/WeatherApp/blob/2d4e3db0df6f15fe5f688391a2eda647be3f9cb1/Carthage/Checkouts/PromiseKit/Categories/CloudKit/CKDatabase%2BPromise.swift#L17


extension CKDatabase {
  public func fetchRecordWithID(recordID: CKRecord.ID) -> Promise<(CKRecord?,Error?)> {
    return Promise.init(resolver: { seal in
      fetch(withRecordID: recordID, completionHandler: { record,error in seal.fulfill((record,error)) } )
    })
  }
  
  public func save(record: CKRecord) -> Promise<(CKRecord?,Error?)> {
    return Promise.init(resolver: { seal in
      save(record, completionHandler: { record,error in seal.fulfill((record,error)) } )
    })
  }
}
