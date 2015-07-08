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

#import "SXCXcodeGroupMember.h"
#import "SXCXcodeFileType.h"

@class SXCProject;

/**
* Represents a file resource in an xcode project.
*/
@interface SXCSourceFile : NSObject<SXCXcodeGroupMember>
{

@private
    SXCProject *_project;

    NSNumber *_isBuildFile;
    NSString *_buildFileKey;
    NSString *_name;
    NSString *_sourceTree;
    NSString *_key;
    NSString *_path;
    SXCXcodeFileType _type;
}

@property (nonatomic, readonly) SXCXcodeFileType type;
@property (nonatomic, strong, readonly) NSString *key;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong, readonly) NSString *sourceTree;
@property (nonatomic, strong) NSString *path;

+ (instancetype)sourceFileWithProject:(SXCProject *)project
                                  key:(NSString *)key
                                 type:(SXCXcodeFileType)type
                                 name:(NSString *)name
                           sourceTree:(NSString *)tree
                                 path:(NSString *)path;

/**
* If yes, indicates the file is able to be included for compilation in an `XCTarget`.
*/
- (BOOL)isBuildFile;
- (BOOL)canBecomeBuildFile;

- (SXCXcodeMemberType)buildPhase;

- (NSString *)buildFileKey;

/**
* Adds this file to the project as an `xcode_BuildFile`, ready to be included in targets.
*/
- (void)becomeBuildFile;

/**
* Method for setting Compiler Flags for individual build files
*
* @param value String value to set in Compiler Flags
*/
- (void)setCompilerFlags:(NSString *)value;

@end
