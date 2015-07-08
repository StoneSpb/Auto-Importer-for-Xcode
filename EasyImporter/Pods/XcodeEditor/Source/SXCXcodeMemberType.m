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

#import "SXCXcodeMemberType.h"

static NSString* const kSXCXcodeMemberTypePBXNil = @"PBXNilType";
static NSString* const kSXCXcodeMemberTypePBXBuildFile = @"PBXBuildFile";
static NSString* const kSXCXcodeMemberTypePBXContainerItemProxy = @"PBXContainerItemProxy";
static NSString* const kSXCXcodeMemberTypePBXCopyFilesBuildPhase = @"PBXCopyFilesBuildPhase";
static NSString* const kSXCXcodeMemberTypePBXFileReference = @"PBXFileReference";
static NSString* const kSXCXcodeMemberTypePBXFrameworksBuildPhase = @"PBXFrameworksBuildPhase";
static NSString* const kSXCXcodeMemberTypePBXGroup = @"PBXGroup";
static NSString* const kSXCXcodeMemberTypePBXNativeTarget = @"PBXNativeTarget";
static NSString* const kSXCXcodeMemberTypePBXProject = @"PBXProject";
static NSString* const kSXCXcodeMemberTypePBXReferenceProxy = @"PBXReferenceProxy";
static NSString* const kSXCXcodeMemberTypePBXResourcesBuildPhase = @"PBXResourcesBuildPhase";
static NSString* const kSXCXcodeMemberTypePBXSourcesBuildPhase = @"PBXSourcesBuildPhase";
static NSString* const kSXCXcodeMemberTypePBXTargetDependency = @"PBXTargetDependency";
static NSString* const kSXCXcodeMemberTypePBXVariantGroup = @"PBXVariantGroup";
static NSString* const kSXCXcodeMemberTypeXCBuildConfiguration = @"XCBuildConfiguration";
static NSString* const kSXCXcodeMemberTypeXCConfigurationList = @"XCConfigurationList";

static NSDictionary* DictionaryWithProjectNodeTypesAsStrings() {
    // This is the most vital operation on adding 500+ files
    // So, we caching this dictionary
    static NSDictionary* _projectNodeTypesAsStrings;
    if (_projectNodeTypesAsStrings) {
        return _projectNodeTypesAsStrings;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _projectNodeTypesAsStrings = @{
            kSXCXcodeMemberTypePBXNil                  : @(SXCXcodeMemberTypePBXNil),
            kSXCXcodeMemberTypePBXBuildFile            : @(SXCXcodeMemberTypePBXBuildFile),
            kSXCXcodeMemberTypePBXContainerItemProxy   : @(SXCXcodeMemberTypePBXContainerItemProxy),
            kSXCXcodeMemberTypePBXCopyFilesBuildPhase  : @(SXCXcodeMemberTypePBXCopyFilesBuildPhase),
            kSXCXcodeMemberTypePBXFileReference        : @(SXCXcodeMemberTypePBXFileReference),
            kSXCXcodeMemberTypePBXFrameworksBuildPhase : @(SXCXcodeMemberTypePBXFrameworksBuildPhase),
            kSXCXcodeMemberTypePBXGroup                : @(SXCXcodeMemberTypePBXGroup),
            kSXCXcodeMemberTypePBXNativeTarget         : @(SXCXcodeMemberTypePBXNativeTarget),
            kSXCXcodeMemberTypePBXProject              : @(SXCXcodeMemberTypePBXProject),
            kSXCXcodeMemberTypePBXReferenceProxy       : @(SXCXcodeMemberTypePBXReferenceProxy),
            kSXCXcodeMemberTypePBXResourcesBuildPhase  : @(SXCXcodeMemberTypePBXResourcesBuildPhase),
            kSXCXcodeMemberTypePBXSourcesBuildPhase    : @(SXCXcodeMemberTypePBXSourcesBuildPhase),
            kSXCXcodeMemberTypePBXTargetDependency     : @(SXCXcodeMemberTypePBXTargetDependency),
            kSXCXcodeMemberTypePBXVariantGroup         : @(SXCXcodeMemberTypePBXVariantGroup),
            kSXCXcodeMemberTypeXCBuildConfiguration    : @(SXCXcodeMemberTypeXCBuildConfiguration),
            kSXCXcodeMemberTypeXCConfigurationList     : @(SXCXcodeMemberTypeXCConfigurationList),
        };
    });
    return _projectNodeTypesAsStrings;
}

@implementation NSString (SXCXcodeMemberType)

+ (NSString*)sxc_stringFromMemberType:(SXCXcodeMemberType)nodeType {
    NSDictionary* nodeTypesToString = DictionaryWithProjectNodeTypesAsStrings();
    return [[nodeTypesToString allKeysForObject:@(nodeType)] firstObject];
}


- (SXCXcodeMemberType)sxc_asMemberType {
    NSDictionary* nodeTypesToString = DictionaryWithProjectNodeTypesAsStrings();
    return (SXCXcodeMemberType) [[nodeTypesToString objectForKey:self] intValue];
}

- (BOOL)sxc_hasFileReferenceType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXFileReference];
}

- (BOOL)sxc_hasFileReferenceOrReferenceProxyType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXFileReference] ||
        [self isEqualToString:kSXCXcodeMemberTypePBXReferenceProxy];
}

- (BOOL)sxc_hasReferenceProxyType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXReferenceProxy];
}

- (BOOL)sxc_hasGroupType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXGroup] ||
        [self isEqualToString:kSXCXcodeMemberTypePBXVariantGroup];
}

- (BOOL)sxc_hasProjectType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXProject];
}

- (BOOL)sxc_hasNativeTargetType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXNativeTarget];
}

- (BOOL)sxc_hasBuildFileType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXBuildFile];
}

- (BOOL)sxc_hasBuildConfigurationType {
    return [self isEqualToString:kSXCXcodeMemberTypeXCBuildConfiguration];
}

- (BOOL)sxc_hasContainerItemProxyType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXContainerItemProxy];
}

- (BOOL)sxc_hasResourcesBuildPhaseType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXResourcesBuildPhase];
}

- (BOOL)sxc_hasSourcesOrFrameworksBuildPhaseType {
    return [self isEqualToString:kSXCXcodeMemberTypePBXSourcesBuildPhase] ||
        [self isEqualToString:kSXCXcodeMemberTypePBXFrameworksBuildPhase];
}

@end
