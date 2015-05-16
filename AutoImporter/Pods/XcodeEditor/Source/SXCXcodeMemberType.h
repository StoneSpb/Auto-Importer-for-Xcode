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

typedef enum
{
    SXCXcodeMemberTypePBXNil,
    SXCXcodeMemberTypePBXBuildFile,
    SXCXcodeMemberTypePBXContainerItemProxy,
    SXCXcodeMemberTypePBXCopyFilesBuildPhase,
    SXCXcodeMemberTypePBXFileReference,
    SXCXcodeMemberTypePBXFrameworksBuildPhase,
    SXCXcodeMemberTypePBXGroup,
    SXCXcodeMemberTypePBXNativeTarget,
    SXCXcodeMemberTypePBXProject,
    SXCXcodeMemberTypePBXReferenceProxy,
    SXCXcodeMemberTypePBXResourcesBuildPhase,
    SXCXcodeMemberTypePBXSourcesBuildPhase,
    SXCXcodeMemberTypePBXTargetDependency,
    SXCXcodeMemberTypePBXVariantGroup,
    SXCXcodeMemberTypeXCBuildConfiguration,
    SXCXcodeMemberTypeXCConfigurationList
} SXCXcodeMemberType;

@interface NSString (SXCXcodeMemberType)

+ (NSString*)sxc_stringFromMemberType:(SXCXcodeMemberType)nodeType;

- (SXCXcodeMemberType)sxc_asMemberType;

- (BOOL)sxc_hasFileReferenceType;
- (BOOL)sxc_hasFileReferenceOrReferenceProxyType;
- (BOOL)sxc_hasReferenceProxyType;
- (BOOL)sxc_hasGroupType;
- (BOOL)sxc_hasProjectType;
- (BOOL)sxc_hasNativeTargetType;
- (BOOL)sxc_hasBuildFileType;
- (BOOL)sxc_hasBuildConfigurationType;
- (BOOL)sxc_hasContainerItemProxyType;
- (BOOL)sxc_hasResourcesBuildPhaseType;
- (BOOL)sxc_hasSourcesOrFrameworksBuildPhaseType;

@end
