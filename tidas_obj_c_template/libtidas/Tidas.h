//
//  Tidas.h
//  tidas_objc_prototype
//
//  Created by ryan on 7/1/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//
#import "DataUtils.h"
#import "TidasErrors.h"

@interface Tidas : NSObject

+ (Tidas *) sharedInstance;

- (void) generateEnrollmentRequestWithCompletion:(void (^)(NSString *dataString, NSError *err))completion;

- (void) generateValidationRequestForData:(NSData *)data withCompletion:(void(^) (NSString *dataString, NSError *err))completion;
- (void) generateValidationRequestForString:(NSString *)string withCompletion:(void(^) (NSString *dataString, NSError *err))completion;

- (void) resetKeychain;

@end
