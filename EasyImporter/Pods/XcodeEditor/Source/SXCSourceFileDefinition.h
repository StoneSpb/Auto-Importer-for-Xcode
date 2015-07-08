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

#import <Foundation/Foundation.h>

#import "SXCAbstractDefinition.h"
#import "SXCXcodeFileType.h"

@interface SXCSourceFileDefinition : SXCAbstractDefinition
{
    NSString* _sourceFileName;
    SXCXcodeFileType _type;
    NSData* _data;
}

@property(nonatomic, strong, readonly) NSString* sourceFileName;
@property(nonatomic, strong, readonly) NSData* data;
@property(nonatomic, readonly) SXCXcodeFileType type;

+ (instancetype)sourceDefinitionWithName:(NSString*)name text:(NSString*)text type:(SXCXcodeFileType)type;
+ (instancetype)sourceDefinitionWithName:(NSString*)name data:(NSData*)data type:(SXCXcodeFileType)type;

@end
