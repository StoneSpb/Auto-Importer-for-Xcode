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

#import "SXCSourceFile.h"

#import "SXCGroup.h"
#import "SXCProject.h"
#import "Utils/SXCKeyBuilder.h"

@implementation SXCSourceFile

@synthesize type = _type;
@synthesize key = _key;
@synthesize sourceTree = _sourceTree;

//-------------------------------------------------------------------------------------------
#pragma mark - Class Methods
//-------------------------------------------------------------------------------------------

+ (instancetype)sourceFileWithProject:(SXCProject *)project
                                  key:(NSString *)key
                                 type:(SXCXcodeFileType)type
                                 name:(NSString *)name
                           sourceTree:(NSString *)tree
                                 path:(NSString *)path
{
    return [[self alloc] initWithProject:project key:key type:type name:name sourceTree:tree path:path];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Initialization & Destruction
//-------------------------------------------------------------------------------------------

- (instancetype)initWithProject:(SXCProject *)project
                            key:(NSString *)key
                           type:(SXCXcodeFileType)type
                           name:(NSString *)name
                     sourceTree:(NSString *)tree
                           path:(NSString *)path
{
    self = [super init];
    if (self) {
        _project = project;
        _key = [key copy];
        _type = type;
        _name = [name copy];
        _sourceTree = [tree copy];
        _path = [path copy];
    }
    return self;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Interface Methods
//-------------------------------------------------------------------------------------------

// Goes to the entry for this object in the project and sets a value for one of the keys, such as name, path, etc.
- (void)setValue:(id)value forProjectItemPropertyWithKey:(NSString *)key
{
    NSMutableDictionary *objects = _project.objects;
    NSMutableDictionary *obj = [objects[_key] mutableCopy];
    if (nil == obj) {
        [NSException raise:@"Project item not found" format:@"Project item with key %@ not found.", _key];
    }
    obj[key] = value;
    objects[_key] = obj;
}

- (NSString *)name
{
    return _name;
}

- (void)setName:(NSString *)name
{
    _name = [name copy];

    [self setValue:name forProjectItemPropertyWithKey:@"name"];
}

- (NSString *)path
{
    return _path;
}

- (void)setPath:(NSString *)path
{
    _path = [path copy];

    [self setValue:path forProjectItemPropertyWithKey:@"path"];
}

- (BOOL)isBuildFile
{
    if ([self canBecomeBuildFile] && _isBuildFile == nil) {
        _isBuildFile = @NO;
        for (NSDictionary* obj in [_project.objects objectEnumerator]) {
            if ([obj[@"isa"] sxc_hasBuildFileType]) {
                if ([obj[@"fileRef"] isEqualToString:_key]) {
                    _isBuildFile = @YES;
                }
            }
        };
    }
    return [_isBuildFile boolValue];
}

- (BOOL)canBecomeBuildFile
{
    return
        _type == SXCXcodeFileTypeSourceCodeObjC ||
        _type == SXCXcodeFileTypeSourceCodeObjCPlusPlus ||
        _type == SXCXcodeFileTypeSourceCodeCPlusPlus ||
        _type == SXCXcodeFileTypeXibFile ||
        _type == SXCXcodeFileTypeFramework ||
        _type == SXCXcodeFileTypeImageResourcePNG ||
        _type == SXCXcodeFileTypeHTML ||
        _type == SXCXcodeFileTypeBundle ||
        _type == SXCXcodeFileTypeArchive;
}

- (SXCXcodeMemberType)buildPhase
{
    if (_type == SXCXcodeFileTypeSourceCodeObjC ||
        _type == SXCXcodeFileTypeSourceCodeObjCPlusPlus ||
        _type == SXCXcodeFileTypeSourceCodeCPlusPlus ||
        _type == SXCXcodeFileTypeXibFile) {
        return SXCXcodeMemberTypePBXSourcesBuildPhase;
    }
    else if (_type == SXCXcodeFileTypeFramework) {
        return SXCXcodeMemberTypePBXFrameworksBuildPhase;
    }
    else if (_type == SXCXcodeFileTypeImageResourcePNG ||
             _type == SXCXcodeFileTypeHTML ||
             _type == SXCXcodeFileTypeBundle) {
        return SXCXcodeMemberTypePBXResourcesBuildPhase;
    }
    else if (_type == SXCXcodeFileTypeArchive) {
        return SXCXcodeMemberTypePBXFrameworksBuildPhase;
    }
    return SXCXcodeMemberTypePBXNil;
}

- (NSString *)buildFileKey
{
    if (_buildFileKey == nil) {
        [_project.objects enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
            if ([obj[@"isa"] sxc_hasBuildFileType]) {
                if ([obj[@"fileRef"] isEqualToString:_key]) {
                    _buildFileKey = [key copy];
                }
            }
        }];
    }
    return [_buildFileKey copy];
}

- (void)becomeBuildFile
{
    if (![self isBuildFile]) {
        if ([self canBecomeBuildFile]) {
            NSMutableDictionary *sourceBuildFile = [NSMutableDictionary dictionary];
            sourceBuildFile[@"isa"] = [NSString sxc_stringFromMemberType:SXCXcodeMemberTypePBXBuildFile];
            sourceBuildFile[@"fileRef"] = _key;
            NSString *buildFileKey = [[SXCKeyBuilder forItemNamed:[_name stringByAppendingString:@".buildFile"]] build];
            _project.objects[buildFileKey] = sourceBuildFile;
        }
        else if (_type == SXCXcodeFileTypeFramework) {
            [NSException raise:NSInvalidArgumentException format:@"Add framework to target not implemented yet."];
        }
        else {
            [NSException raise:NSInvalidArgumentException format:@"Project file of type %@ can't become a build file.",
                                                                 SXCNSStringFromSXCXcodeFileType(_type)];
        }
    }
}

- (void)setCompilerFlags:(NSString *)value
{
    NSMutableDictionary *objects = _project.objects;
    NSMutableDictionary *objectArrayCopy = [objects mutableCopy];
    [objectArrayCopy enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
        if ([obj[@"isa"] sxc_hasBuildFileType]) {
            if ([obj[@"fileRef"] isEqualToString:self.key]) {
                NSMutableDictionary *replaceBuildFile = [obj mutableCopy];
                NSDictionary *compilerFlagsDict = @{ @"COMPILER_FLAGS" : value };
                NSMutableDictionary *settings = replaceBuildFile[@"settings"];
                if (settings[@"COMPILER_FLAGS"] != nil) {
                    NSMutableDictionary *newSettings = [settings mutableCopy];
                    [newSettings removeObjectForKey:@"COMPILER_FLAGS"];
                    replaceBuildFile[@"settings"] = compilerFlagsDict;
                }
                else {
                    replaceBuildFile[@"settings"] = compilerFlagsDict;
                }
                objects[key] = replaceBuildFile;
            }
        }
    }];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Protocol Methods

- (SXCXcodeMemberType)groupMemberType
{
    return SXCXcodeMemberTypePBXFileReference;
}

- (NSString *)displayName
{
    return _name;
}

- (NSString *)pathRelativeToProjectRoot
{
    NSString *parentPath = [[_project groupForGroupMemberWithKey:_key] pathRelativeToProjectRoot];
    NSString *result = [parentPath stringByAppendingPathComponent:_name];
    return result;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Utility Methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"Project file: key=%@, name=%@, fullPath=%@", _key, _name,
                                      [self pathRelativeToProjectRoot]];
}

@end
