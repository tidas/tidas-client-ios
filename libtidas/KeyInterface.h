//
//  KeyInterface.h
//  tidas_objc_prototype
//
//  Created by Nicholas Esposito on 9/18/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TidasErrors.h"

#define kTidasPrivateKeyName @"com.trailofbits.tidas.private"
#define kTidasPublicKeyName @"com.trailofbits.tidas.public"

@interface KeyInterface : NSObject

+ (bool) generateTouchIDKeyPair;

+ (bool) publicKeyExists;
+ (bool) deletePubKey;
+ (bool) deletePrivateKey;
+ (SecKeyRef) lookupPublicKeyRef;
+ (NSData *) publicKeyBits;
+ (SecKeyRef) lookupPrivateKeyRef;

+ (void)generateSignatureForData:(NSData *)inputData withCompletion:(void(^)(NSData *data, NSError *err))completion;

@end
