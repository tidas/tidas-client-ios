//
//  DataUtils.h
//  tidas_objc_prototype
//
//  Created by Nicholas Esposito on 7/30/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#define kChosenDigestLength		CC_SHA1_DIGEST_LENGTH

@interface DataUtils : NSObject

+ (NSData *)sha1FromInputData:(NSData *)inputData;

+ (NSData *)timestampDataForTime:(time_t)time;
+ (NSData *)timestampData;

+ (NSString *)hexStringForData:(NSData *)data;

@end
