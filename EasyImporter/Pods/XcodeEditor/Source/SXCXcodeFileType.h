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

typedef NS_OPTIONS(NSInteger, SXCXcodeFileType)
{
    SXCXcodeFileTypeNil = 0,                     // Unknown filetype
    SXCXcodeFileTypeFramework = 1,               // .framework
    SXCXcodeFileTypePropertyList = 2,            // .plist
    SXCXcodeFileTypeSourceCodeHeader = 3,        // .h
    SXCXcodeFileTypeSourceCodeObjC = 4,          // .m
    SXCXcodeFileTypeSourceCodeObjCPlusPlus = 5,  // .mm
    SXCXcodeFileTypeSourceCodeCPlusPlus = 6,     // .cpp
    SXCXcodeFileTypeXibFile = 7,                 // .xib
    SXCXcodeFileTypeImageResourcePNG = 8,        // .png
    SXCXcodeFileTypeBundle = 9,                  // .bundle  .octet
    SXCXcodeFileTypeArchive = 10,                // .a files
    SXCXcodeFileTypeHTML = 11,                   // HTML file
    SXCXcodeFileTypeTEXT = 12,                   // Some text file
    SXCXcodeFileTypeXcodeProject = 13,           // .xcodeproj
    SXCXcodeFileTypeFolder = 14                  // a Folder reference
};

NSString* SXCNSStringFromSXCXcodeFileType(SXCXcodeFileType type);

SXCXcodeFileType SXCXcodeFileTypeFromStringRepresentation(NSString* string);

SXCXcodeFileType SXCXcodeFileTypeFromFileName(NSString* fileName);
