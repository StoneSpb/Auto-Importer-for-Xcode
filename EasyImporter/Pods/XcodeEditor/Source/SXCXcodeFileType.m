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

#import "SXCXcodeFileType.h"

static NSDictionary* SXCNSDictionaryWithXCFileReferenceTypes()
{
    static NSDictionary* dictionary;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dictionary = @{
            @"sourcecode.c.h"        : @(SXCXcodeFileTypeSourceCodeHeader),
            @"sourcecode.c.objc"     : @(SXCXcodeFileTypeSourceCodeObjC),
            @"wrapper.framework"     : @(SXCXcodeFileTypeFramework),
            @"text.plist.strings"    : @(SXCXcodeFileTypePropertyList),
            @"sourcecode.cpp.objcpp" : @(SXCXcodeFileTypeSourceCodeObjCPlusPlus),
            @"sourcecode.cpp.cpp"    : @(SXCXcodeFileTypeSourceCodeCPlusPlus),
            @"file.xib"              : @(SXCXcodeFileTypeXibFile),
            @"image.png"             : @(SXCXcodeFileTypeImageResourcePNG),
            @"wrapper.cfbundle"      : @(SXCXcodeFileTypeBundle),
            @"archive.ar"            : @(SXCXcodeFileTypeArchive),
            @"text.html"             : @(SXCXcodeFileTypeHTML),
            @"text"                  : @(SXCXcodeFileTypeTEXT),
            @"wrapper.pb-project"    : @(SXCXcodeFileTypeXcodeProject),
            @"folder"                : @(SXCXcodeFileTypeFolder)
        };
    });

    return dictionary;
}

NSString* SXCNSStringFromSXCXcodeFileType(SXCXcodeFileType type)
{
    return [[SXCNSDictionaryWithXCFileReferenceTypes() allKeysForObject:@(type)] firstObject];
}

SXCXcodeFileType SXCXcodeFileTypeFromStringRepresentation(NSString* string)
{
    NSDictionary* typeStrings = SXCNSDictionaryWithXCFileReferenceTypes();
    NSNumber* typeValue = typeStrings[string];

    if (typeValue) {
        return (SXCXcodeFileType) [typeValue intValue];
    } else {
        return SXCXcodeFileTypeNil;
    }
}

SXCXcodeFileType SXCXcodeFileTypeFromFileName(NSString* fileName)
{
    if ([fileName hasSuffix:@".h"] ||
        [fileName hasSuffix:@".hh"] ||
        [fileName hasSuffix:@".hpp"] ||
        [fileName hasSuffix:@".hxx"]) {
        return SXCXcodeFileTypeSourceCodeHeader;
    }

    if ([fileName hasSuffix:@".c"] ||
        [fileName hasSuffix:@".m"]) {
        return SXCXcodeFileTypeSourceCodeObjC;
    }

    if ([fileName hasSuffix:@".mm"]) {
        return SXCXcodeFileTypeSourceCodeObjCPlusPlus;
    }

    if ([fileName hasSuffix:@".cpp"]) {
        return SXCXcodeFileTypeSourceCodeCPlusPlus;
    }

    return SXCXcodeFileTypeNil;
}
