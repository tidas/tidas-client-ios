//
//  Tidas.m
//  tidas_objc_prototype
//
//  Created by ryan on 7/1/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "Tidas.h"
#import "TidasBlob.h"
#import "KeyInterface.h"

@implementation Tidas : NSObject

static Tidas  *_sharedInstance;

+(Tidas *)sharedInstance
{
    if (!_sharedInstance){
      _sharedInstance = [Tidas new];
    }
    return _sharedInstance;
}

+ (int)touchIDAvailable
{
  if ([LAContext class]) {
    BOOL available =  [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    if (available)
      return errTidasSuccess;
  }
  return errNoTouchID;
}

- (BOOL)_init_touchid
{
  // Lookup key
  if (![KeyInterface lookupPrivateKeyRef])
  {
    if (![KeyInterface generateTouchIDKeyPair])
    {
      return NO;
    }
  }
  return YES;
}

- (id)init
{
  BOOL rv;

  // Check for TouchID/SE
  int touchIDCheck = [Tidas touchIDAvailable];
  if (touchIDCheck != errTidasSuccess) {
    NSLog(@"%@", [self errorForCode:errNoTouchID]);
    return false;
  }
  else {
    rv = [self _init_touchid];
  }
  if (rv) {
    return self;
  }
  return nil;
}

///// Real Tidas Methods
- (void) generateEnrollmentRequestWithData:(NSData *)data completion:(void (^)(NSString *dataString, NSError *err))completion {
  int touchIDCheck = [Tidas touchIDAvailable];
  if (touchIDCheck != errTidasSuccess){
    return completion(nil, [self errorForCode:errNoTouchID]);
  }
  TidasBlob *_blob = [TidasBlob initWithData:data];
  __block NSString *innerString;
  __block NSError  *innerError;
  [_blob base64EncodedEnrollmentDataWithCompletion:^(NSString *encodedString, NSError *encodingErr){
    innerString = encodedString;
    innerError = encodingErr;
  }];
  if (innerError)
    return completion(nil, [self errorForCode:innerError.code]);
  else {
    return completion(innerString, nil);
  }

}

- (void) generateValidationRequestForData:(NSData *)data withCompletion:(void(^) (NSString *dataString, NSError *err))completion {
  int touchIDCheck = [Tidas touchIDAvailable];
  if (touchIDCheck != errTidasSuccess){
    return completion(nil, [self errorForCode:errNoTouchID]);
  }
  
  int validation = [self validationAllowed:data];
  if (validation != errTidasSuccess){
    return completion(nil, [self errorForCode:errBadData]);
  }

  TidasBlob *_blob = [TidasBlob initWithData:data];
  __block NSString *innerString;
  __block NSError  *innerError;
  [_blob base64EncodedValidationDataWithCompletion:^(NSString *encodedString, NSError *encodingErr){
    innerString = encodedString;
    innerError = encodingErr;
  }];

  if (innerError) {
      return completion(nil, [self errorForCode:innerError.code]);
    }
    else {
      return completion(innerString, nil);
    }

}

///// Convenience Methods

  // Enrollment
- (void) generateEnrollmentRequestWithCompletion:(void (^)(NSString *dataString, NSError *err))completion {
  __block NSString *innerString;
  __block NSError  *innerError;
  [self generateEnrollmentRequestWithData:nil completion:^(NSString *encodedString, NSError *encodingErr) {
    innerString = encodedString;
    innerError  = encodingErr;
  }];
  if (innerError)
    return completion(nil, innerError);
  else
    return completion(innerString, nil);
}

  // Validation
- (void) generateValidationRequestForString:(NSString *)inputString withCompletion:(void(^) (NSString *dataString, NSError *err))completion {
  __block NSString *innerString;
  __block NSError  *innerError;
  NSData *stringData = [NSData dataWithBytes:[inputString UTF8String] length:[inputString length]];
  [self generateValidationRequestForData:stringData withCompletion:^(NSString *encodedString, NSError *encodingErr) {
    innerString = encodedString;
    innerError  = encodingErr;
  }];
  if (innerError)
    return completion(nil, innerError);
  else
    return completion(innerString, nil);
}


///// Validation
- (int)validationAllowed:(NSData *)data
{
  int touchIdCheck = [Tidas touchIDAvailable];
  if (touchIdCheck != errTidasSuccess)
    return touchIdCheck;
  if (data == NULL || data.length == 0){
    return errBadData;
  }
  return errTidasSuccess;
}

- (void)resetKeychain {
  [KeyInterface deletePubKey];
  [KeyInterface deletePrivateKey];
  [KeyInterface generateTouchIDKeyPair];
}

- (NSError *)errorForCode:(long)code {
  switch (code) {
    case (1):
      return [NSError errorWithDomain:@"TidasError" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Touch ID unavailable - Tidas cannot start without TouchID enabled and at least one fingerprint present"}];
    case (2):
      return [NSError errorWithDomain:@"TidasError" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Data is empty - please pass in at least one byte to create a validation request"}];
    case (-128):
      return [NSError errorWithDomain:@"TidasError" code:3 userInfo:@{NSLocalizedDescriptionKey: @"User Canceled the TouchID authentication"}];
    case (-25293):
      return [NSError errorWithDomain:@"TidasError" code:4 userInfo:@{NSLocalizedDescriptionKey: @"User failed the TouchID authentication"}];
  }
  return [NSError errorWithDomain:@"TidasError" code:5 userInfo:@{NSLocalizedDescriptionKey: @"Unexpected Tidas runtime error - please report this to us!"}];
}

@end
