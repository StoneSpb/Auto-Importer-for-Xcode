////////////////////////////////////////////////////////////////////////////////
//
//  JASPER BLUES
//  Copyright 2012 - 2013 Jasper Blues
//  All Rights Reserved.
//
//  NOTICE: Jasper Blues permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "SXCKeyBuilder.h"

#import <CommonCrypto/CommonDigest.h>

#define HASH_VALUE_STORAGE_SIZE 48

typedef struct
{
    char value[CC_MD5_DIGEST_LENGTH];
} SXCHashValueMD5Hash;

@implementation SXCKeyBuilder
{
    unsigned char _value[HASH_VALUE_STORAGE_SIZE];
}

/* ================================================= Class Methods ================================================== */
+ (instancetype)forItemNamed:(NSString*)name
{
    NSData* data = [name dataUsingEncoding:NSUTF8StringEncoding];
    return [[SXCKeyBuilder alloc] initHashValueMD5HashWithBytes:[data bytes] length:[data length]];
}

+ (instancetype)createUnique
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFUUIDBytes bytes = CFUUIDGetUUIDBytes(theUUID);
    CFRelease(theUUID);

    return [[SXCKeyBuilder alloc] initHashValueMD5HashWithBytes:&bytes length:sizeof(bytes)];
}

/* ================================================== Initializers ================================================== */
- (instancetype)initHashValueMD5HashWithBytes:(const void*)bytes length:(NSUInteger)length
{
    self = [super init];
    if (self != nil)
    {
        CC_MD5(bytes, (int) length, _value);
    }
    return self;
}

/* ================================================ Interface Methods =============================================== */
- (NSString*)build
{
    NSInteger byteLength = sizeof(SXCHashValueMD5Hash);
    NSMutableString* stringValue = [NSMutableString stringWithCapacity:byteLength * 2];
    NSInteger i;
    for (i = 0; i < byteLength; i++)
    {
        [stringValue appendFormat:@"%02x", _value[i]];
    }
    return [[stringValue substringToIndex:24] uppercaseString];
}

@end
