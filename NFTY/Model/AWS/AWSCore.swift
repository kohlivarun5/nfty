//
//  AWSCore.swift
//  NFTY
//
//  Created by Varun Kohli on 4/15/22.
//

import Foundation
import AWSS3
import ClientRuntime
import AWSClientRuntime


struct AWSClient {
  private let s3Client = try S3Client(region: "us-west-1")
  func putObject(bucket:String,key:String, _ dataToUpload:Data) {
    let body = ByteStream.from(data: dataToUpload)
    s3Client.putObject(input: PutObjectInput(body: body, bucket: bucket,
                                             key: key, metadata: metadata)) { result in
      switch(result) {
      case .success(let response):
        if let eTag = response.eTag {
          print("Successfully uploaded the file with the etag: \(eTag)")
        }
      case .failure(let err):
        print(err)
      }
    }
  }
  
  func getObject(bucket:String,key:String) {
    
    s3Client.getObject(input: GetObjectInput(bucket: bucket,
                                             key: key)) { result in
      switch(result) {
      case .success(let response):
        guard let body = response.body else {
          return
        }
        let data = body.toBytes().toData()
        writeToFile(data: data)
      case .failure(let err):
        print(err)
      }
    }
    
  }
  
  
}
