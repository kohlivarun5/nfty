//
//  nscalc-Bridging-Header.h
//  NFTY
//
//  Created by Varun Kohli on 7/7/22.
//

#ifndef nscalc_Bridging_Header_h
#define nscalc_Bridging_Header_h

#import <Vision/Vision.h>

@interface VNCreateNeuralHashprintRequest : VNRequest

@end

@interface VNEspressoModelImageprint : NSObject

@property(readonly, nonatomic) unsigned long long version;
@property(readonly, nonatomic) unsigned long long serializedLength;
@property(readonly, nonatomic) unsigned long long requestRevision;
- (nullable NSData *)serializeStateAndReturnError:(NSError **)arg1;
- (nullable NSData *)encodeHashDescriptorWithBase64EncodingAndReturnError:(NSError **)arg1;
- (id)labelsAndConfidence;
- (id)originatingRequestSpecifier;
- (NSObject *)descriptorData;
+ (unsigned long long)currentVersion;
+ (BOOL)supportsSecureCoding;

@end

@interface VN6kBnCOr2mZlSV6yV1dLwB: VNRequest

@property(strong, nonatomic) VNEspressoModelImageprint* inputSignatureprint;
@property(readwrite, nonatomic) NSUInteger imageSignatureprintType;
@property(readwrite, nonatomic) NSUInteger imageSignatureHashType;

@end

@interface VN3XKGTKNBvy6h4RFtpxLyW : VNObservation

- (VNEspressoModelImageprint *)imageSignatureprint;
- (VNEspressoModelImageprint *)imageSignatureHash;

@end

@interface VNImageNeuralHashprintObservation: VNObservation

- (nullable VNEspressoModelImageprint*) imageNeuralHashprint;

@end

#endif /* nscalc_Bridging_Header_h */
