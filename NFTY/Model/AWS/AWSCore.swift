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
  
  private func getClient() async -> S3Client? {
    return try? await S3Client(region: "us-west-1")
  }
  
  func putObject(bucket:String,key:String, _ dataToUpload:Data) async -> () {
    guard let s3Client = await getClient() else { return }
    let body = ByteStream.from(data: dataToUpload)
    guard let _ = try? await s3Client.putObject(input: PutObjectInput(body: body, bucket: bucket,
                                                                key: key, metadata: nil)) else { return }
  }
  
  func getObject(bucket:String,key:String) async -> Data? {
    guard let s3Client = await getClient() else { return nil }
    guard let result = try? await s3Client.getObject(input: GetObjectInput(bucket: bucket,
                                                                           key: key)) else { return nil }
    guard let body = result.body else { return nil }
    return body.toBytes().toData()
  }
  
  
}
