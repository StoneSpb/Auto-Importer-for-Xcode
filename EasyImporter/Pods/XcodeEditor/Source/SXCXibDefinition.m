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

#import "SXCXibDefinition.h"

@implementation SXCXibDefinition

@synthesize name = _name;
@synthesize content = _content;

/* ================================================================================================================== */
#pragma mark - Class Methods

+ (instancetype)xibDefinitionWithName:(NSString*)name
{
    return [[self alloc] initWithName:name];
}

+ (instancetype)xibDefinitionWithName:(NSString*)name content:(NSString*)content
{
    return [[self alloc] initWithName:name content:content];
}

/* ================================================================================================================== */
#pragma mark - Initialization & Destruction

- (instancetype)initWithName:(NSString*)name
{
    return [self initWithName:name content:nil];
}

- (instancetype)initWithName:(NSString*)name content:(NSString*)content
{
    self = [super init];
    if (self)
    {
        _name = [name copy];
        _content = [content copy];
    }
    return self;
}

/* ================================================================================================================== */
#pragma mark - Interface Methods

- (NSString*)xibFileName
{
    return [_name stringByAppendingString:@".xib"];
}

@end
