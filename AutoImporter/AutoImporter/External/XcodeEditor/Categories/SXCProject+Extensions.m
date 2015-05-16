//
//  XCProject+NSDate.m
//  MHImportBuster
//
//  Created by Marko Hlebar on 10/06/2014.
//  Copyright (c) 2014 Marko Hlebar. All rights reserved.
//

#import "SXCProject+Extensions.h"

@interface SXCProject ()

- (NSArray*)projectFilesOfType:(SXCXcodeFileType)projectFileType;

@end

@implementation SXCProject (NSDate)

- (NSDate *)dateModified {
    NSURL *fileUrl = [NSURL fileURLWithPath:self.filePath];
    NSDate *date = nil;
    [fileUrl getResourceValue:&date
                       forKey:NSURLContentModificationDateKey
                        error:nil];
    return date;
}

@end

@implementation SXCProject (MHSubprojects)

- (NSArray *)subProjectFiles {
    return [self projectFilesOfType:SXCXcodeFileTypeXcodeProject];
}

@end
