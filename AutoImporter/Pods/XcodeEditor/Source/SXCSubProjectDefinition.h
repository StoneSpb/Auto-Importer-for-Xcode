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

@class SXCProject;

@interface SXCSubProjectDefinition : SXCAbstractDefinition
{
    NSString *_name;
    NSString *_path;
    SXCXcodeFileType _type;
    SXCProject *_subProject;
    SXCProject *_parentProject;
    NSString *_key;
    NSString *_fullProjectPath;
    NSString *_relativePath;
}

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, readonly) SXCXcodeFileType type;
@property (nonatomic, strong, readonly) SXCProject *subProject;
@property (nonatomic, strong, readonly) SXCProject *parentProject;
@property (nonatomic, strong, readonly) NSString *key;
@property (nonatomic, strong, readwrite) NSString *fullProjectPath;

+ (instancetype)subProjectDefinitionWithName:(NSString *)name
                                        path:(NSString *)path
                               parentProject:(SXCProject *)parentProject;

- (NSString *)projectFileName;
- (NSString *)fullPathName;

- (NSArray *)buildProductNames;

- (NSString *)projectKey;

- (NSString *)pathRelativeToProjectRoot;

- (void)setFullProjectPath:(NSString *)fullProjectPath groupPath:(NSString *)groupPath;

@end
