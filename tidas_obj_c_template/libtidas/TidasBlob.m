//
//  TidasBlob.m
//  tidas_objc_prototype
//
//  Created by Nicholas Esposito on 7/30/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#import "TidasBlob.h"
#import "DataUtils.h"
#import "Tidas.h"
#import "KeyInterface.h"


@implementation TidasBlob

enum SerializationField {
    f_platform        = 0x00,
    f_blob_data       = 0x01,
    f_timestamp       = 0x02,
    f_dataHash        = 0x03,
    f_signature       = 0x04,
    f_publicKeyData   = 0x05
    
};

@synthesize blobData;
@synthesize timestampData;

+(TidasBlob *)initWithData:(NSData *)data
{
    TidasBlob *_blob = [TidasBlob new];
    _blob.blobData = data;
    _blob.timestampData = [DataUtils timestampData];
    return _blob;
}

- (void) encodedBasicDataWithCompletion:(void(^)(NSData *data, NSError *err))completion
{
  __block NSData *signatureData;
  __block NSError *innerError;
  [self signaturewithCompletion:^(NSData *data, NSError *err) {
    signatureData = data;
    innerError = err;
  }];
  
  if (innerError) {
    return completion(nil, innerError);
  }
  else {
    return completion([self buildBlobWithSignature:signatureData], nil);
  }
}

- (NSData *)buildBlobWithSignature:(NSData*)signatureData {
  NSMutableData *outputData = [NSMutableData new];
  
  const char platform[] = {f_platform, 0x01, 0x00, 0x00,0x00, 0x00};
  NSData *platformData = [NSData dataWithBytes:platform length:sizeof(platform)];
  
  [outputData appendData:platformData];
  [outputData appendData:[self tlvWithIdentifier:f_blob_data data: [self blobData] ]];
  [outputData appendData:[self tlvWithIdentifier:f_timestamp data: [self timestampData] ]];
  [outputData appendData:[self tlvWithIdentifier:f_dataHash  data: [self dataHash] ]];
  [outputData appendData:[self tlvWithIdentifier:f_signature data: signatureData ]];
  
  return outputData;
}

- (void)encodedEnrollmentDataWithCompletion:(void(^)(NSData *data, NSError *err))completion
{
  NSMutableData *outputData = [NSMutableData new];

  __block NSData *innerData;
  __block NSError *innerError;

  [self encodedBasicDataWithCompletion:^(NSData *data, NSError *err) {
    innerData = data;
    innerError = err;
  }];
  if (innerError){
    return completion(nil, innerError);
  }
  else {
    [outputData appendData:innerData];
    [outputData appendData:[self tlvWithIdentifier:f_publicKeyData data:[KeyInterface publicKeyBits]]];
    return completion(outputData, nil);
  }
}

- (void) base64EncodedEnrollmentDataWithCompletion:(void(^)(NSString *dataString, NSError *err))completion
{
  __block NSError *innerErr;
  __block NSData *innerData;
  [self encodedEnrollmentDataWithCompletion:^(NSData *data, NSError *err){
    innerErr = err;
    innerData = data;
  }];
  if (innerErr)
    return completion(nil, innerErr);
  else
    return completion([innerData base64EncodedStringWithOptions:0], nil);
}

- (void)base64EncodedValidationDataWithCompletion:(void(^)(NSString *dataString, NSError *err))completion
{
  __block NSError *innerError;
  __block NSData *innerData;
  [self encodedEnrollmentDataWithCompletion:^(NSData *data, NSError *err){
    innerData = data;
    innerError = err;
  }];
  if (innerError){
    return completion(nil, innerError);
  }
  else{
    return completion([innerData base64EncodedStringWithOptions:0], nil);
  }

}

- (NSData *) dataToSign
{
  NSMutableData *_dataToSign = [NSMutableData new];
  [_dataToSign appendData:blobData];
  [_dataToSign appendData:timestampData];
  return _dataToSign;
}

- (NSData *) dataHash
{
  return [DataUtils sha1FromInputData:[self dataToSign]];
}

- (void) signaturewithCompletion:(void(^)(NSData *data, NSError *err))completion
{
  __block NSData *innerData;
  __block NSError *innerError;
  [KeyInterface generateSignatureForData:[self dataHash] withCompletion:^(NSData *data, NSError *err) {
    innerData = data;
    innerError = err;
  }];
  if (innerError){
    return completion(nil, innerError);
  }
  else {
    return completion(innerData, nil);
  }

}

- (NSData *)tlvWithIdentifier:(const char)identifier data:(NSData *)data {
  NSMutableData *tlvData = [NSMutableData new];
  uint32_t dataSize = (uint32_t)[data length];
  [tlvData appendBytes:&identifier length:1];
  [tlvData appendBytes:&dataSize length:4];
  [tlvData appendBytes:[data bytes] length:dataSize];
  return tlvData;
}

@end
