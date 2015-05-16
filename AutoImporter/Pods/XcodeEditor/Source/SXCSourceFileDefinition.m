////////////////////////////////////////////////////////////////////////////////
//
//  JASPER BLUES
//  Copyright 2012 Jasper Blues
//  All Rights Reserved.
//
//  NOTICE: Jasper Blues permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "SXCSourceFileDefinition.h"

@implementation SXCSourceFileDefinition

@synthesize sourceFileName = _sourceFileName;
@synthesize type = _type;
@synthesize data = _data;

/* ================================================================================================================== */
#pragma mark - Class Methods

+ (instancetype)sourceDefinitionWithName:(NSString*)name text:(NSString*)text type:(SXCXcodeFileType)type
{
    return [[self alloc] initWithName:name text:text type:type];
}

+ (instancetype)sourceDefinitionWithName:(NSString*)name data:(NSData*)data type:(SXCXcodeFileType)type
{
    return [[self alloc] initWithName:name data:data type:type];
}

/* ================================================================================================================== */
#pragma mark - Initialization & Destruction

- (instancetype)initWithName:(NSString*)name text:(NSString*)text type:(SXCXcodeFileType)type
{
    self = [super init];
    if (self)
    {
        _sourceFileName = [name copy];
        _data = [[text dataUsingEncoding:NSUTF8StringEncoding] copy];
        _type = type;
    }
    return self;
}

- (instancetype)initWithName:(NSString*)name data:(NSData*)data type:(SXCXcodeFileType)type
{
    self = [super init];
    if (self)
    {
        _sourceFileName = [name copy];
        _data = [data copy];
        _type = type;
    }
    return self;
}

@end
