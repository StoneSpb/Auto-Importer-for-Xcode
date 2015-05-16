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

#import <Foundation/Foundation.h>

@interface SXCKeyBuilder : NSObject

+ (instancetype)forItemNamed:(NSString*)name;
+ (instancetype)createUnique;

- (instancetype)initHashValueMD5HashWithBytes:(const void*)bytes length:(NSUInteger)length;

- (NSString*)build;

@end
