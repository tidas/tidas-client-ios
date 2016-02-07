//
//  DataUtils.m
//  tidas_objc_prototype
//
//  Created by Nicholas Esposito on 7/30/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#import "DataUtils.h"
#import "Tidas.h"


@implementation DataUtils

+ (NSData *)sha1FromInputData:(NSData *)inputData
{
    unsigned char shaChars[kChosenDigestLength];
	CC_SHA1_CTX ctx;
	
	memset((void *)shaChars, 0x0, kChosenDigestLength);
	
	CC_SHA1_Init(&ctx);
	CC_SHA1_Update(&ctx, (void *)inputData.bytes, (CC_LONG)inputData.length);
	CC_SHA1_Final(shaChars, &ctx);
	
	NSData *resultData = [NSData dataWithBytes:shaChars length:kChosenDigestLength];
    return resultData;
}

+ (NSData *)timestampDataForTime:(time_t)time
{
    time_t unix_time = (time_t) [[NSDate date] timeIntervalSince1970];
    NSData *timeData = [NSData dataWithBytes:&unix_time length:sizeof(time_t)];
    return timeData;
}

+ (NSData *)timestampData
{
    time_t unix_time_now = (time_t) [[NSDate date] timeIntervalSince1970];
    return [DataUtils timestampDataForTime:unix_time_now];
}

// http://stackoverflow.com/questions/7520615/how-to-convert-an-nsdata-into-an-nsstring-hex-string?lq=1

static inline char itoh(int i) {
    if (i > 9) return 'A' + (i - 10);
    return '0' + i;
}

+ (NSString *)hexStringForData:(NSData *)data {
    NSUInteger i, len;
    unsigned char *buf, *bytes;
    
    len = data.length;
    bytes = (unsigned char*)data.bytes;
    buf = malloc(len*2);
    
    for (i=0; i<len; i++) {
        buf[i*2] = itoh((bytes[i] >> 4) & 0xF);
        buf[i*2+1] = itoh(bytes[i] & 0xF);
    }
    
    return [[NSString alloc] initWithBytesNoCopy:buf
                                          length:len*2
                                        encoding:NSASCIIStringEncoding
                                    freeWhenDone:YES];
}

@end
