//
//  TidasEnrollment.h
//  tidas_objc_prototype
//
//  Created by Nicholas Esposito on 7/30/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TidasBlob : NSObject

@property (nonatomic, strong) NSData  *blobData;
@property (nonatomic, strong) NSData  *timestampData;

+ (id) initWithData:(NSData *)data;

- (void) base64EncodedEnrollmentDataWithCompletion:(void(^)(NSString *dataString, NSError *err))completion;
- (void) base64EncodedValidationDataWithCompletion:(void(^)(NSString *dataString, NSError *err))completion;

@end
